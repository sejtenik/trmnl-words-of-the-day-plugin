require_relative 'word_of_the_day_provider'
require 'addressable/uri'
require 'open-uri'

class PolishWordProvider < MarkupDocumentProvider
end

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


class PwnParser < PolishWordProvider
  def fetch_word(doc)
    day_word_box = doc.at_css(".sjp-slowo-dnia")
    word_link = day_word_box.at_css("a")
    word_link.text.strip
  end

  def fetch_definitions(doc, word)
    day_word_box = doc.at_css(".sjp-slowo-dnia")
    word_link = day_word_box.at_css("a")

    word_url = Addressable::URI.parse(word_link['href']).normalize.to_s

    word_html = URI.open(word_url)
    word_doc = Nokogiri::HTML(word_html)
    definition_text = word_doc.text.match(/«(.*?)»/)
    definition = definition_text[1]&.strip

    {
      definition: definition,
      url: word_url
    }
  end

  def url
    "https://sjp.pwn.pl"
  end

end
