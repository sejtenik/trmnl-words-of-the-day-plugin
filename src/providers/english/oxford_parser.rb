class OxfordParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css(".wotd h3 a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    part_of_speech = doc.at_css(".wotdPos")&.text&.strip
    definition = doc.at_css(".wotdDef")&.text&.strip

    link = doc.at_css(".wotd h3 a")['href']

    #TODO goto link and get pronunciation and example

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: url + link
    }
  end

  def url
    "https://www.oed.com"
  end

end

