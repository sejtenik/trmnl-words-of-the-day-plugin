class DictionaryComParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css(".otd-item-headword__word h1.js-fit-text")&.text&.strip
  end

  def fetch_definitions(doc, word)
    pronunciation = doc.at_css(".otd-item-headword__ipa")&.text&.strip
    pronunciation.gsub!(/^\[|\]$/, '').strip! if pronunciation
    part_of_speech = doc.at_css(".otd-item-headword__pos p span.italic")&.text&.strip
    definition = doc.at_css(".otd-item-headword__pos p:not(.italic) + p")&.text&.strip
    definition_url = doc.at('a.otd-item-headword__anchors-link')['href']

    #TODO get an example

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      url: definition_url
    }
  end

  def url
    "https://www.dictionary.com/e/word-of-the-day/"
  end

end


