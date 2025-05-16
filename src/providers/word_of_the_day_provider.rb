require 'nokogiri'
require 'moneta'
require 'time'
require 'fileutils'

require_relative '../tools'
require_relative '../url_shortener'
require_relative '../gpt_tool'

class WordOfTheDayProvider
  attr_writer :doc

  CACHE_TTL = 24 * 60 * 60
  @providers = []

  def fetch
    @cache = Moneta.new(:File, dir: 'cache', serializer: :json)
    cache_key = "#{src_desc}.json"

    cache_value = fetch_cache_or_refresh(cache_key) do
      @doc = get_doc
      @word = fetch_word
    end

    if cache_value
      return cache_value
    end

    definitions = fetch_definitions

    if may_be_enhanced?
      definitions = GptTool.new.enhance_definition(definitions.merge(word: @word))
    end

    result = definitions.merge(
      word: Tools.nvl(@word, '>>Word not found<<'),
      definition: Tools.nvl(definitions[:definition], '>>Definition not found<<'),
      source: Tools.nvl(definitions[:source], src_desc),
      url: prepare_short_url(definitions),
      creation_date: Time.now
    ).compact

    @cache[cache_key] = result
    result
  rescue StaleDefinitionError
    raise
  rescue => e
    error =  "#{Time.now} #{src_desc}\n#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
    puts error
    line_separator = "\n========================\n"
    save_logs([error, @doc.to_s, @word_doc.to_s].join(line_separator))
    raise
  ensure
    @cache.close
  end

  def fetch_word
    raise NotImplementedError, "Subclasses must implement `fetch_word`"
  end

  def fetch_definitions
    raise NotImplementedError, "Subclasses must implement `fetch_definitions`"
  end

  def src_desc
    raise NotImplementedError, "Subclasses must implement `src_desc`"
  end

  def get_doc
    raise NotImplementedError, "Subclasses must implement `get_doc`"
  end

  def may_be_enhanced?
    true
  end

  def self.providers
    self.leaf_classes(WordOfTheDayProvider)
  end

  def self.leaf_classes(klass)
    subclasses = klass.subclasses

    if subclasses.empty?
      [klass]
    else
      subclasses.flat_map { |subclass| leaf_classes(subclass) }
    end
  end

  private
  def prepare_short_url(definitions)
    target_url = definitions[:url] || (respond_to?(:url) ? url : nil)
    target_url ? UrlShortener.shorten_url_with_tinyurl(target_url) : nil
  end

  def fetch_cache_or_refresh(cache_key)
    unless @cache.key?(cache_key)
      yield
      return
    end

    value = @cache[cache_key].transform_keys(&:to_sym)
    age = Time.now - Time.parse(value[:creation_date])

    if age <= CACHE_TTL
      puts 'Using cache'
      @cache[cache_key] = value #bump cache file modification time attribute
      value
    else
      new_word = yield
      if new_word == value[:word]
        raise StaleDefinitionError, "Cached value for #{cache_key} - #{value[:word]} is stale and no changes detected in fresh data."
      end
    end
  end

  def save_logs(resp)
    if resp.nil?
      return
    end

    log_folder = 'logs'
    FileUtils.mkdir_p(log_folder)

    timestamp = Time.now.strftime('%Y%m%d_%H%M%S.%L') # Format: YYYYMMDD_HHMMSS.mmm
    class_name = self.class.name
    log_file = File.join(log_folder, "#{timestamp}_#{class_name}.log")

    File.open(log_file, 'w') do |file|
      file.write(resp)
    end
  end

end

