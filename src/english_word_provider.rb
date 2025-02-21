require 'nokogiri'
require_relative 'word_of_the_day_provider'

class EnglishWordProvider < MarkupDocumentProvider
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
    definition_url = doc.at('a.otd-item-headword__anchors-link')['href']

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      url: definition_url
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


class MerriamWebsterParser < EnglishWordProvider
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

    link = doc.at('a:contains("See the entry >")')['href']

    {
      part_of_speech: part_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      example: example,
      url: link
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
      p.next_element&.name == "a" && p.next_element["href"]&.include?(remove_accents(word.gsub(" ", "-")))
    }&.text&.strip

    link = doc.at_css(".wotd-hw a")['href']

    {
      pronunciation: pronunciation,
      definition: definition,
      url: url + link
    }
  end

  def url
    "https://dictionary.cambridge.org"
  end

  private
  def remove_accents(text)
    text.unicode_normalize(:nfd).gsub(/\p{Mn}/, '')
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

    link = doc.at('a[title*="Word of the day"]:contains("view")')['href']

    uri = URI.parse(url)


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

class OxfordParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css(".wotd h3 a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    part_of_speech = doc.at_css(".wotdPos")&.text&.strip
    definition = doc.at_css(".wotdDef")&.text&.strip

    link = doc.at_css(".wotd h3 a")['href']

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: url + link
    }
  end

  def url
    "https://www.oed.com"
  end

end

class LongmanParser < EnglishWordProvider
  def fetch_word(doc)
    word_element = doc.at_css("#wotd .title_entry a")
    word_element&.text&.strip
  end

  def fetch_definitions(doc, word)
    definition = doc.at_css("#wotd .ldoceEntry .newline a")&.text&.strip
    link = doc.at_css("#wotd .title_entry a")['href']

    {
      definition: definition,
      url: link
    }
  end

  def url
    "https://www.ldoceonline.com/"
  end

end


class WordReferenceParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css('.post-img a')['alt'].split(':').last.strip
  end

  def fetch_definitions(doc, word)
    link = doc.at_css('.post-img a')['href']
    word_url = Addressable::URI.parse(link).normalize.to_s

    word_html = URI.open(word_url)
    word_doc = Nokogiri::HTML(word_html)

    pronunciation = word_doc.at_css('.section.word .translation')&.text&.strip&.gsub('/', '')
    parts_of_speech = word_doc.at_css('.section.word .description')&.text&.strip&.gsub(/[()]/, '')
    definition = word_doc.at_css('.section.text-area p').text.strip
    examples = word_doc.css('.section.list-w-title ul li')&.first&.text&.strip

    {
      part_of_speech: parts_of_speech,
      pronunciation: pronunciation,
      definition: definition,
      example: examples,
      url: link
    }
  end

  def url
    "https://daily.wordreference.com/intermediate-word-of-the-day/"
  end
end

#TODO: replace with an actual Wordnik REST API
class WordnikParser < EnglishWordProvider
  def fetch_word(doc)
    doc.at_css('h1 a')&.text&.strip
  end

  def fetch_definitions(doc, word)
    part_of_speech = doc.at_css('.word-module.module-definitions li abbr')&.text&.strip
    definition = doc.at_css('.word-module.module-definitions li')&.text&.strip&.sub(/^#{part_of_speech}\s+/, '')
    example = doc.at_css('.word-module.module-examples .examples li .text')&.text&.strip

    {
      part_of_speech: part_of_speech,
      definition: definition,
      example: example
    }
  end

  def url
    "https://www.wordnik.com/word-of-the-day"
  end

end

class WordsmithParser < EnglishWordProvider

  def fetch_word(doc)
    doc.at_css('item title').text.strip
  end

  def fetch_definitions(doc, word)
    description = doc.at_css('item description').text.strip

    part_of_speech = description.split(':').first.strip

    definition = description.split(':')[1]&.strip&.sub(/^\d+\.\s*/, '')

    link = doc.at_css('item link').text.strip

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: link
    }
  end

  def url
    "https://wordsmith.org/awad/rss1.xml"
  end

end

