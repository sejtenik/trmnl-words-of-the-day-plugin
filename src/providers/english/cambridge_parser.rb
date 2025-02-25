require_relative '../../tools'

class CambridgeParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css(".wotd-hw a")&.text&.strip
  end

  def fetch_definitions(doc, word)
    pronunciation = doc.at_css(".ipa.dipa")&.text&.strip
    pronunciation.gsub!(/^\//, '').gsub!(/\/$/, '') if pronunciation

    definition = doc.css("p").find { |p|
      p.next_element&.name == "a" && p.next_element["href"]&.include?(Tools.remove_accents(word.gsub(" ", "-")))
    }&.text&.strip

    link = doc.at_css(".wotd-hw a")['href']

    #TODO go to 'link' and the grab part of speech and an example usage

    {
      pronunciation: pronunciation,
      definition: definition,
      url: url + link
    }
  end

  def url
    "https://dictionary.cambridge.org"
  end

end

