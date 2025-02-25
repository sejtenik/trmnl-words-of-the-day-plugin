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

end
