class WordnikParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css('h1 a')&.text&.strip
  end

  def fetch_definitions(doc, word)
    part_of_speech = doc.at_css('.word-module.module-definitions li abbr')&.text&.strip
    definition = doc.at_css('.word-module.module-definitions li')&.text&.strip&.sub(/^#{part_of_speech}\s+/, '')
    example = doc.at_css('.word-module.module-examples .examples li .text')&.text&.strip

    {
      part_of_speech: part_of_speech,
      definition: definition,
      example: example
    }
  end

  def url
    "https://www.wordnik.com/word-of-the-day"
  end

end

