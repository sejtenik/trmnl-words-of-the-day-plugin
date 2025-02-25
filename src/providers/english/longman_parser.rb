class LongmanParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css("#wotd .title_entry a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    definition = doc.at_css("#wotd .ldoceEntry .newline a")&.text&.strip
    link = doc.at_css("#wotd .title_entry a")['href']

    #TODO go to link and get part of speech, pronunciation and example

    {
      definition: definition,
      url: link
    }
  end

  def url
    "https://www.ldoceonline.com/"
  end

end


