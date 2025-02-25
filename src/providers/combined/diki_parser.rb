require_relative '../english/english_word_provider'

class DikiParser < EnglishWordProvider

  def fetch_word(doc)
    word_box = doc.at_css(".wordofthedaybox")
    word_box.at_css(".hws .hw a").text.strip
  end

  def fetch_definitions(doc, word)
    word_box = doc.at_css(".wordofthedaybox")
    part_of_speech = word_box.at_css(".partOfSpeech")&.text&.strip
    meanings = doc.css('ol.foreignToNativeMeanings li').map do |li|
      li.xpath(".//span[@class='hw'] | .//span[@class='hwcomma']").map(&:text).join('; ').strip
    end.join(", ")

    first_example = word_box.at_css(".exampleSentence")
    example= ''

    if first_example
      english_example = first_example.text.strip.split("\n")&.first&.strip
      polish_translation = first_example.at_css(".exampleSentenceTranslation")&.text&.strip

      example = "#{english_example} #{polish_translation}"
    end

    link = word_box&.at('a.plainLink')['href']


    {
      part_of_speech: part_of_speech,
      definition: meanings,
      example: example,
      url: URI.parse(url).host + link
    }
  end

  def url
    "https://www.diki.pl/dictionary/word-of-the-day"
  end

end


