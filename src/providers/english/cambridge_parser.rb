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

    link = url + doc.at_css(".wotd-hw a")['href']

    word_doc = get_details_doc(link)

    part_of_speech = word_doc.at_css('.pos.dpos').text.strip

    level = word_doc.at_css('.epp-xref.dxref')&.text&.strip
    example = word_doc.at_css('.eg.dexamp')&.text&.strip

    {
      pronunciation: pronunciation,
      definition: definition,
      part_of_speech: part_of_speech,
      level: level,
      example: example,
      url: link
    }
  end

  def url
    "https://dictionary.cambridge.org"
  end

end

