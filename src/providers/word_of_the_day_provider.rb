require 'open-uri'
require 'nokogiri'
require 'moneta'
require_relative '../tools'
require_relative '../url_shortener'

class WordOfTheDayProvider
  @providers = []

  def fetch
    cache = Moneta.new(:File, dir: 'cache', serializer: :json)

    doc = get_doc
    word = fetch_word(doc)

    cache_key = "#{src_desc}_#{word}.json"

    if cache.key?(cache_key)
      puts 'Using cache'
      return fetch_with_touch(cache, cache_key)
    end

    definitions = fetch_definitions(doc, word)

    result = definitions.merge(
      word: Tools.nvl(word, '>>Word not found<<'),
      definition: Tools.nvl(definitions[:definition], '>>Definition not found<<'),
      source: Tools.nvl(definitions[:source], src_desc),
      url: prepare_short_url(definitions)
    ).compact

    cache[cache_key] = result
    result
  rescue => e
    puts "#{src_desc} #{e.full_message}"
    raise
  ensure
    cache.close
  end

  def fetch_word(doc)
    raise NotImplementedError, "Subclasses must implement `fetch_word`"
  end

  def fetch_definitions(doc, word)
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

  def fetch_with_touch(cache, key)
    value = cache[key]

    if value
      cache[key] = value
    end

    value
  end

end

