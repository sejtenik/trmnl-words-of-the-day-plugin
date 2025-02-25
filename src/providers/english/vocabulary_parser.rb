require 'addressable/uri'

#FIXME - on some environments it produces: 403 forbidden
class VocabularyParser < EnglishWordProvider

  def fetch_word(doc)
    doc.at('a.word-of-the-day')&.text&.strip
  end

  def fetch_definitions(doc, word)
    link = doc.at('a.word-of-the-day')['href']
    definition = doc.at('p.txt-wod-usage')&.inner_html&.force_encoding("utf-8")&.strip
    uri = URI.parse(url)
    link_parsed = Addressable::URI.parse(link).normalize.to_s

    word_url = "#{uri.scheme}://#{uri.host}#{link_parsed}"
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

