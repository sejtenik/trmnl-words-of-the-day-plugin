class TheFreeDictionaryParser < EnglishWordProvider

  def fetch_word
    @doc.at_css("#Content_CA_WOD_0_DataZone h3 a").text.strip
  end

  def fetch_definitions
    definition = @doc.at_css("#Content_CA_WOD_0_DataZone td span").text.strip
    part_of_speech = @doc.at_css("#Content_CA_WOD_0_DataZone td:nth-of-type(2)")&.text&.strip[/\((.*?)\)/, 1]
    link = "#{url}#{@word}"
    usage = @doc.css("#Content_CA_WOD_0_DataZone td").last.text.strip.split("Discuss").first.strip

    @word_doc = get_details_doc(link)

    pronunciation_html = @word_doc.at_css("span.pron")&.inner_html&.gsub(/[()]/, '')
    pronunciation_html = CGI.unescapeHTML(pronunciation_html)

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: link,
      example: usage,
      pronunciation: pronunciation_html
    }
  end

  def url
    "https://www.thefreedictionary.com/"
  end
end

