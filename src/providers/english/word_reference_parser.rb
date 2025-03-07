class WordReferenceParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css('.post-img a')['alt'].split(':').last.strip
  end

  def fetch_definitions(doc, word)
    link = doc.at_css('.post-img a')['href']

    word_doc = get_details_doc(link)

    pronunciation = word_doc.at_css('.section.word .translation')&.text&.strip&.gsub('/', '')
    parts_of_speech = word_doc.at_css('.section.word .description')&.text&.strip&.gsub(/[()]/, '')
    definition = word_doc.at_css('.section.text-area p').text.strip
    examples = word_doc.css('.section.list-w-title ul li')&.first&.text&.strip

    {
      part_of_speech: parts_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      example: examples,
      url: link
    }
  end

  #TODO: replace with an actual Wordnik REST API
  def url
    "https://daily.wordreference.com/intermediate-word-of-the-day/"
  end
end
