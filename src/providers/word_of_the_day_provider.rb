require 'nokogiri'
require 'moneta'
require 'time'
require 'fileutils'

require_relative '../tools'
require_relative '../url_shortener'

class WordOfTheDayProvider
  attr_writer :doc

  CACHE_TTL = 24 * 60 * 60
  @providers = []

  def fetch
    @cache = Moneta.new(:File, dir: 'cache', serializer: :json)

    @doc = get_doc
    @word = fetch_word

    cache_key = "#{src_desc}_#{@word}.json"

    if @cache.key?(cache_key)
      puts 'Using cache'
      return fetch_with_checks(cache_key)
    end

    definitions = fetch_definitions

    result = definitions.merge(
      word: Tools.nvl(@word, '>>Word not found<<'),
      definition: Tools.nvl(definitions[:definition], '>>Definition not found<<'),
      source: Tools.nvl(definitions[:source], src_desc),
      url: prepare_short_url(definitions),
      creation_date: Time.now
    ).compact

    @cache[cache_key] = result
    result
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

  def fetch_with_checks(key)
    value = @cache[key]

    value = value.transform_keys(&:to_sym)

    if value[:creation_date].nil? || Time.now - Time.parse(value[:creation_date]) > CACHE_TTL
      raise StaleDefinitionError, "Definition for #{key} is outdated - creation_date: #{value[:creation_date]}"
    end

    if value
      @cache[key] = value
    end

    value
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

