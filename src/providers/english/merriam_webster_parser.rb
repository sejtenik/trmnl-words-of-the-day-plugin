class MerriamWebsterParser < EnglishWordProvider
  def fetch_word
    word_element = @doc.at_css('.word-header-txt')
    word_element&.text&.strip
  end


  def fetch_definitions
    part_of_speech_element = @doc.at_css('.main-attr')
    part_of_speech = part_of_speech_element&.text&.strip

    pronunciation_element = @doc.at_css('.word-syllables')
    pronunciation = pronunciation_element&.text&.strip

    definition_container = @doc.at_css(".wod-definition-container")

    definition = []
    definition_container.css("p").each do |p|
      break if p.text.strip.start_with?("//")
      definition << p.text.strip
    end

    definition = definition.join(" ").strip

    example = definition_container.css("p").find { |p| p.text.strip.start_with?("//") }
                &.inner_html&.gsub("//", "")&.strip

    link = @doc.at('a:contains("See the entry >")')['href']

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      example: example,
      url: link
    }
  end

  def url
    'https://www.merriam-webster.com/word-of-the-day'
  end

end

