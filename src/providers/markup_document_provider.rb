require_relative 'word_of_the_day_provider'
require 'httparty'
require 'addressable/uri'

#Provides definition from HTML and XML for given url
class MarkupDocumentProvider < WordOfTheDayProvider

  def url
    raise NotImplementedError, "Subclasses must implement `url`"
  end

  def src_desc
    URI.parse(url).host
  end

  def get_doc
    puts "Calling #{url}"
    response = HTTParty.get(url)
    content_type = response.headers['content-type']

    puts response.headers

    if content_type.include?('xml')
      Nokogiri::XML(response.body)
    elsif content_type.include?('html')
      Nokogiri::HTML(response.body)
    else
      raise "Unsupported content type: #{content_type}"
    end
  rescue => e
    raise RuntimeError.new("Error opening URL: #{url}"), cause: e
  end

  private
  #TODO remove duplicated code with get_doc method
  def get_details_doc(link, add_user_agent = false)
    word_url = normalize_url(link)
    puts "Calling #{word_url}"

    headers = {}
    if add_user_agent
      headers = {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    end
    response = HTTParty.get(word_url, headers: headers)
    puts response.headers
    content_type = response.headers['content-type']
    if content_type.include?('html')
      Nokogiri::HTML(response.body)
    else
      raise "Unsupported content type: #{content_type} for #{word_url}"
    end
  rescue => e
    raise RuntimeError.new("Error opening URL: #{word_url}"), cause: e
  end

  def normalize_url(link)
    Addressable::URI.parse(link)&.normalize.to_s
  end

  def resolve_url(link)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}#{link}"
  end

end
