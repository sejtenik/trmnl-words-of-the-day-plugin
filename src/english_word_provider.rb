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

class VocabularyParser < EnglishWordProvider

  def fetch_word(doc)
    doc.at('a.word-of-the-day')&.text&.strip
  end

  def fetch_definitions(doc, word)
    link = doc.at('a.word-of-the-day')['href']
    definition = doc.at('p.txt-wod-usage')&.text&.strip
    uri = URI.parse(url)
    word_url = "#{uri.scheme}://#{uri.host}#{link}"
    word_html = URI.open(word_url)
    word_doc = Nokogiri::HTML(word_html)
    ipa = word_doc.at('div.ipa-with-audio span.span-replace-h3')&.inner_html&.force_encoding("utf-8")&.strip&.gsub('/', '')
    part_of_speech = word_doc.at('div.pos-icon')&.text&.strip

    {
      definition: definition,
      pronunciation: ipa,
      part_of_speech: part_of_speech,
      url: word_url
    }
  end

  def url
    "https://www.vocabulary.com/word-of-the-day/"
  end
end

class TheFreeDictionaryParser < EnglishWordProvider

  def fetch_word(doc)
    doc.at_css("#Content_CA_WOD_0_DataZone h3 a").text.strip
  end

  def fetch_definitions(doc, word)
    definition = doc.at_css("#Content_CA_WOD_0_DataZone td span").text.strip
    part_of_speech = doc.at_css("#Content_CA_WOD_0_DataZone td:nth-of-type(2)")&.text&.strip[/\((.*?)\)/, 1]
    link = "#{url}#{word}"
    usage = doc.css("#Content_CA_WOD_0_DataZone td").last.text.strip.split("Discuss").first.strip

    word_html = URI.open(link)
    word_doc = Nokogiri::HTML(word_html)

    pronunciation_html = word_doc.at_css("span.pron")&.inner_html&.gsub(/[()]/, '')
    pronunciation_html = CGI.unescapeHTML(pronunciation_html)

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: link,
      example: usage,
      pronunciation: pronunciation_html
    }
  end

  def url
    "https://www.thefreedictionary.com/"
  end
end

class NYTimesParser < EnglishWordProvider

  def fetch_word(doc)
    word_link = doc.at_css('a:has(h3:contains("Word of the Day"))').text.strip
    word_link.split(':').last.strip
  end

  def fetch_definitions(doc, word)

    link = 'https://www.nytimes.com' + doc.at_css('a:has(h3:contains("Word of the Day"))')['href']

    options = {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    word_html = URI.open(link, options)
    word_doc = Nokogiri::HTML(word_html)

    h2 = word_doc.at_css("h2:contains('#{word}')")
    h2_text = h2.text.strip

    pronunciation = h2_text[/\\ (.*?) \\/, 1]&.strip

    part_of_speech = h2_text.split.last.strip

    blockquote = h2.next_element if h2.next_element&.name == 'blockquote'
    definition = blockquote.at_css('p')&.text&.strip.sub(/^: /, '') if blockquote

    {
      definition: definition,
      part_of_speech: part_of_speech,
      url: link,
      pronunciation: pronunciation
    }
  end

  def url
    "https://www.nytimes.com/column/learning-word-of-the-day"
  end
end

class MathrubhumiParser < EnglishWordProvider

  def fetch_word(doc)
    link = doc.at_xpath('//a[h1[contains(text(), "Word of the day")]]')
    link.at_xpath('h1').text[/'.*?'/]&.delete("'")&.strip&.downcase
  end

  def fetch_definitions(doc, word)
    link = 'https://english.mathrubhumi.com' + doc.at_xpath('//a[h1[contains(text(), "Word of the day")]]')['href']
    word_html = URI.open(link)
    word_doc = Nokogiri::HTML(word_html)

    divs = word_doc.css('div.mpp-story-content-details-main.my-3')

    meaning = nil
    example = nil
    pronunciation = nil

    divs.each_with_index do |div, index|
      case div.at_css('p strong')&.text
      when 'Meaning'
        meaning = divs[index + 1]&.at_css('p')&.text&.strip
      when 'Pronunciation'
        pronunciation = divs[index + 1]&.at_css('p')&.text&.strip
      when 'Examples from books and articles'
        example = divs[index + 1]&.at_css('li')&.text&.strip
      end
    end

    {
      definition: meaning,
      url: link,
      pronunciation: pronunciation,
      example: example
    }
  end

  def url
    "https://english.mathrubhumi.com/topics/tag/word_of_the_day"
  end
end

class WordleParser < EnglishWordProvider

  def fetch_word(doc)
    table = doc.at_css('table')
    rows = table.css('tbody tr')
    rows[1].css('td')[2]&.text&.strip&.downcase
  end

  def fetch_definitions(doc, word)
    GptWordProvider.new.fetch_definitions(doc, word)
  end

  def url
    "https://wordfinder.yourdictionary.com/wordle/answers/"
  end

  def src_desc
    "Yesterday's Wordle + gpt-4o"
  end

end