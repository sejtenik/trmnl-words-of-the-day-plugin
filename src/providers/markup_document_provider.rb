require_relative 'word_of_the_day_provider'

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

  private
  def get_details_doc(link, add_user_agent = false)
    word_url = normalize_url(link)
    options = {}
    if add_user_agent
      options = {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      }
    end
    response = URI.open(word_url, options)
    if response.content_type.include?('html')
      Nokogiri::HTML(response)
    else
      raise "Unsupported content type: #{response.content_type}"
    end
  end

  def normalize_url(link)
    Addressable::URI.parse(link).normalize.to_s
  end

end
