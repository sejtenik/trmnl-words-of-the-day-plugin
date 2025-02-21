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
      url: prepare_short_url(definitions)
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

  private
  def nvl(string, default)
    string.nil? || string.empty? ? default : string
  end

  #TODO refactor, extract class
  def shorten_url_with_tinyurl(long_url)
    uri = URI("https://api.tinyurl.com/create")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{ENV['TINYURL_API_KEY']}"

    request.body = { url: long_url}.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data.dig("data", "tiny_url")
    else
      puts "Błąd: #{response.code} - #{response.body}"
      nil
    end
  end

  def prepare_short_url(definitions)
    if definitions[:url]
      return shorten_url_with_tinyurl(definitions[:url])
    end

    if respond_to? :url
      return shorten_url_with_tinyurl(url)
    end

    nil
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
