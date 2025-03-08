class OxfordParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css(".wotd h3 a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    part_of_speech = doc.at_css(".wotdPos")&.text&.strip
    definition = doc.at_css(".wotdDef")&.text&.strip

    link = url + doc.at_css(".wotd h3 a")['href'] + '?tl=true'

    @word_doc = get_details_doc(link, true)

    pronunciation = @word_doc.at_css(".pronunciation-ipa")&.text&.strip&.gsub(/^\/|\/$/, '')

    last_quote = @word_doc.at_css('ol.quotation-container')&.css('li.quotation')&.last&.css('.quotation-text')&.text&.strip

    frequency_element = @word_doc.at_css('.frequency-indicator')
    frequency_visual = ""

    if frequency_element && frequency_element['aria-description']
      frequency_description = frequency_element['aria-description']
      if frequency_description =~ /Frequency band: (\d+) out of (\d+)/
        frequency_value = $1.to_i
        frequency_max = $2.to_i
        frequency_visual = "●" * frequency_value + "○" * (frequency_max - frequency_value)
      end
    end

    {
      definition: definition,
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      example: last_quote,
      level: frequency_visual,
      url: link
    }
  end

  def url
    "https://www.oed.com"
  end

end

