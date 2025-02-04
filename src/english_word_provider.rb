require 'nokogiri'
require_relative 'word_of_the_day_provider'

class EnglishWordProvider < HtmlProvider
end

class DictionaryComParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css(".otd-item-headword__word h1.js-fit-text")&.text&.strip
  end

  def fetch_definitions(doc, word)
    pronunciation = doc.at_css(".otd-item-headword__ipa")&.text&.strip
    pronunciation.gsub!(/^\[|\]$/, '').strip! if pronunciation
    part_of_speech = doc.at_css(".otd-item-headword__pos p span.italic")&.text&.strip
    definition = doc.at_css(".otd-item-headword__pos p:not(.italic) + p")&.text&.strip

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      definition: definition,
    }
  end

  def url
    "https://www.dictionary.com/e/word-of-the-day/"
  end

end


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

    {
      part_of_speech: part_of_speech,
      definition: meanings,
      example: example,
    }
  end

  def url
    "https://www.diki.pl/dictionary/word-of-the-day"
  end

end


class MerriamParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css('.word-header-txt')
    word_element&.text&.strip
  end


  def fetch_definitions(doc, word)
    part_of_speech_element = doc.at_css('.main-attr')
    part_of_speech = part_of_speech_element&.text&.strip

    pronunciation_element = doc.at_css('.word-syllables')
    pronunciation = pronunciation_element&.text&.strip

    definition_container = doc.at_css(".wod-definition-container")

    definition = []
    definition_container.css("p").each do |p|
      break if p.text.strip.start_with?("//")
      definition << p.text.strip
    end

    definition = definition.join(" ").strip

    example = definition_container.css("p").find { |p| p.text.strip.start_with?("//") }
                &.inner_html&.gsub("//", "")&.strip
    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      example: example,
    }
  end

  def url
    'https://www.merriam-webster.com/word-of-the-day'
  end

end

class BritannicaParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css(".hw_d .hw_txt, .hw_m .hw_txt")&.text&.strip
  end

  def fetch_definitions(doc, word)
    pronunciation = doc.at_css(".hpron_word")&.text&.strip
    pronunciation.gsub!(/^\//, '').gsub!(/\/$/, '') if pronunciation
    part_of_speech = doc.at_css(".fl")&.text&.strip
    definition = doc.at_css(".midb:first-of-type .midbt p")&.text&.strip.sub(/^\d+ /, '').sub(/^:\s*/, '')
    example = doc.at_css(".midb:first-of-type .vib .vis .vi p")&.text&.strip

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      example: example,
      definition: definition,
    }
  end

  def url
    "https://www.britannica.com/dictionary/eb/word-of-the-day"
  end

end


class CambridgeParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css(".wotd-hw a")&.text&.strip
  end

  def fetch_definitions(doc, word)
    pronunciation = doc.at_css(".ipa.dipa")&.text&.strip
    pronunciation.gsub!(/^\//, '').gsub!(/\/$/, '') if pronunciation

    definition = doc.css("p").find { |p|
      p.next_element&.name == "a" && p.next_element["href"]&.include?(word.gsub(" ", "-"))
    }&.text&.strip

    {
      pronunciation: pronunciation,
      definition: definition,
    }
  end

  def url
    "https://dictionary.cambridge.org/"
  end

end

class WiktionaryParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css("#WOTD-rss-title")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    word_element = doc.at_css("#WOTD-rss-title")
    part_of_speech = word_element.parent.parent.next_element&.text&.strip
    definition = doc.at_css("#WOTD-rss-description ol li")&.text&.strip&.gsub(/^\([^\)]+\)\s*/, '')&.strip

    {
      definition: definition,
      part_of_speech: part_of_speech,
    }
  end

  def url
    "https://en.wiktionary.org/wiki/Wiktionary:Main_Page"
  end

end

class OxfordParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css(".wotd h3 a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    part_of_speech = doc.at_css(".wotdPos")&.text&.strip
    definition = doc.at_css(".wotdDef")&.text&.strip

    {
      definition: definition,
      part_of_speech: part_of_speech,
    }
  end

  def url
    "https://www.oed.com/"
  end

end

class LongmanParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css("#wotd .title_entry a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    definition = doc.at_css("#wotd .ldoceEntry .newline a")&.text&.strip

    {
      definition: definition,
    }
  end

  def url
    "https://www.ldoceonline.com/"
  end

end
