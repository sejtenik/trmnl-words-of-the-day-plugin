class DictionaryComParser < EnglishWordProvider
  def fetch_word
    @doc.at_css(".otd-item-headword__word h1.js-fit-text")&.text&.strip
  end

  def fetch_definitions
    pronunciation = @doc.at_css(".otd-item-headword__ipa")&.text&.strip
    pronunciation.gsub!(/^\[|\]$/, '').strip! if pronunciation
    part_of_speech = @doc.at_css(".otd-item-headword__pos p span.italic")&.text&.strip
    definition = @doc.at_css(".otd-item-headword__pos p:not(.italic) + p")&.text&.strip
    definition_url = @doc.at('a.otd-item-headword__anchors-link')['href']

    examples_section = @doc.xpath("//p[contains(., 'EXAMPLES OF') or contains(., 'EXAMPLES')]").first

    if examples_section
      first_example = examples_section.xpath("following-sibling::ul[1]/li[1]").first&.text&.strip || ""

      first_example = first_example.gsub(/<\/?[^>]*>/, "").gsub(/\s+/, " ").strip
    end

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      example: first_example,
      url: definition_url
    }
  end

  def url
    "https://www.dictionary.com/e/word-of-the-day/"
  end

end


