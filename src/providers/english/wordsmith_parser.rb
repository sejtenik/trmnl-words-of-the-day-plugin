class WordsmithParser < EnglishWordProvider

  def fetch_word(doc)
    doc.at_css('item title').text.strip
  end

  def fetch_definitions(doc, word)
    description = doc.at_css('item description').text.strip

    part_of_speech = description.split(':').first.strip

    definition = description.split(':')[1]&.strip&.sub(/^\d+\.\s*/, '')

    link = doc.at_css('item link').text.strip

    word_doc = get_details_doc(link)

    pronunciation = word_doc.css('div').select do |div|
      div.previous_element&.text&.strip == "PRONUNCIATION:"
    end&.first&.text&.strip&.gsub(/^\(|\)$/, '')

    usage = word_doc.css('div').select do |div|
      div.previous_element&.text&.strip == "USAGE:"
    end&.first&.text&.strip&.gsub(/\n/, ' ')

    if usage =~ /“(.*?)”/m
      usage = $1
    end

    {
      definition: definition,
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      example: usage,
      url: link
    }
  end

  def url
    "https://wordsmith.org/awad/rss1.xml"
  end

end
