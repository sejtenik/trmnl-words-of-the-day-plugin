class WiktionaryParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css("#WOTD-rss-title")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    word_element = doc.at_css("#WOTD-rss-title")
    part_of_speech = word_element.parent.parent.next_element&.text&.strip
    definition = doc.at_css("#WOTD-rss-description ol li")&.text&.strip&.gsub(/^\([^\)]+\)\s*/, '')&.strip

    link = doc.at('a[title*="Word of the day"]:contains("view")')['href']

    uri = URI.parse(url)

    #TODO go to link and get pronunciation and example

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: "#{uri.scheme}://#{uri.host}#{link}"
    }
  end

  def url
    "https://en.wiktionary.org/wiki/Wiktionary:Main_Page"
  end

end

