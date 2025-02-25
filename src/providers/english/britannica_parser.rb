class BritannicaParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css(".hw_d .hw_txt, .hw_m .hw_txt")&.text&.strip
  end

  def fetch_definitions(doc, word)
    pronunciation = doc.at_css(".hpron_word")&.text&.strip
    pronunciation.gsub!(/^\//, '').gsub!(/\/$/, '') if pronunciation
    part_of_speech = doc.at_css(".fl")&.text&.strip
    definition = doc.at_css(".midb:first-of-type .midbt p")&.text&.strip.sub(/^\d+ /, '').sub(/^:\s*/, '')
    example = doc.at_css(".midb:first-of-type .vib .vis .vi p")&.text&.strip

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      example: example,
      definition: definition,
    }
  end

  def url
    "https://www.britannica.com/dictionary/eb/word-of-the-day"
  end

end


