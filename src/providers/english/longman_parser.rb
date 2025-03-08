class LongmanParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css("#wotd .title_entry a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    definition = doc.at_css("#wotd .ldoceEntry .newline a")&.text&.strip
    link = doc.at_css("#wotd .title_entry a")['href']

    @word_doc = get_details_doc(link)

    pronunciation = @word_doc.at_css('.PRON')&.inner_html&.force_encoding("utf-8")&.strip

    part_of_speech = @word_doc.at_css('.POS')&.text&.strip

    example_in_def = @word_doc.at_css('.EXAMPLE')&.text&.strip
    level = @word_doc.at_css('.tooltip.LEVEL')&.inner_html&.force_encoding("utf-8")&.strip

    corpus_example = @word_doc.at_css('.cexa1g1.exa')&.inner_html&.force_encoding("utf-8")&.strip || ""
    corpus_example = corpus_example.gsub(/•/, '').gsub(/<[^>]*>/, '').strip if corpus_example

    example = corpus_example.empty? ? example_in_def : corpus_example

    {
      definition: definition,
      pronunciation: pronunciation,
      part_of_speech: part_of_speech,
      example: example,
      level: level,
      url: link
    }
  end

  def url
    "https://www.ldoceonline.com/"
  end

end


