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
    get_details_doc(url)
  end

  protected
  def get_details_doc(link, add_user_agent = false, headers = {})
    word_url = normalize_url(link)
    puts "Calling #{word_url}"

    if add_user_agent
      headers = {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }.merge(headers)
    end

    response = HTTParty.get(word_url, {headers: headers})
    puts "Request headers: #{response.instance_variable_get('@request')
                                     .instance_variable_get('@raw_request')
                                     .instance_variable_get('@header')
                                     .to_s}"
    puts "Response headers: #{response.headers.to_s}"
    content_type = response.headers['content-type']
    if content_type&.include?('xml')
      Nokogiri::XML(response.body)
    elsif content_type&.include?('html')
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
