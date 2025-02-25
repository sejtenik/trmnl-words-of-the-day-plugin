class WordsmithParser < EnglishWordProvider

  def fetch_word(doc)
    doc.at_css('item title').text.strip
  end

  def fetch_definitions(doc, word)
    description = doc.at_css('item description').text.strip

    part_of_speech = description.split(':').first.strip

    definition = description.split(':')[1]&.strip&.sub(/^\d+\.\s*/, '')

    link = doc.at_css('item link').text.strip

    #TODO go to link and get pronunciation and example

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: link
    }
  end

  def url
    "https://wordsmith.org/awad/rss1.xml"
  end

end
