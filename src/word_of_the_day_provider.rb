require 'open-uri'
require 'nokogiri'

class WordOfTheDayProvider
  @providers = []

  def fetch
    doc = get_doc
    word = fetch_word(doc)
    definitions = fetch_definitions(doc, word)

    definitions.merge(
      word: nvl(word, '>>Word not found<<'),
      definition: nvl(definitions[:definition], '>>Definition not found<<'),
      source: nvl(definitions[:source], src_desc),
      url: nvl(definitions[:url], respond_to?(:url) ? url : nil)
    ).compact
  rescue => e
    {
      word: ">>#{e.class.to_s}<<",
      definition: ">>#{e.message}<<",
      source: src_desc
    }
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

  def nvl(string, default)
    string.nil? || string.empty? ? default : string
  end

end

#Provides definition from HTML and XML for given url
class MarkupDocumentProvider < WordOfTheDayProvider

  def url
    raise NotImplementedError, "Subclasses must implement `url`"
  end

  def src_desc
    URI.parse(url).host
  end

  def get_doc
    response = URI.open(url)
    content_type = response.content_type

    if content_type.include?('xml')
      Nokogiri::XML(response)
    elsif content_type.include?('html')
      Nokogiri::HTML(response)
    else
      raise "Unsupported content type: #{content_type}"
    end
  end

end
