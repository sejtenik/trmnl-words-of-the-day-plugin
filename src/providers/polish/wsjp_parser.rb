class WsjpParser < PolishWordProvider
  def fetch_word(doc)
    day_word_box = doc.at_css(".day-word-box")
    day_word_box.at_css("h4").text.strip
  end

  def fetch_definitions(doc, word)
    day_word_box = doc.at_css(".day-word-box")
    qualifier = day_word_box.at_css(".kwalifikator")&.text&.strip
    definition = day_word_box.css("span").last.text.strip
    link = doc.at('div.day-word-box a')['href']

    {
      qualifier: qualifier,
      definition: definition,
      url: link
    }
  end

  def url
    "https://wsjp.pl"
  end

end


