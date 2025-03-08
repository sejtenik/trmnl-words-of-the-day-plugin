#FIXME - on some environments it produces: 403 forbidden
class VocabularyParser < EnglishWordProvider

  def fetch_word(doc)
    doc.at('a.word-of-the-day')&.text&.strip
  end

  def fetch_definitions(doc, word)
    definition = doc.at('p.txt-wod-usage')&.inner_html&.force_encoding("utf-8")&.strip

    link = doc.at('a.word-of-the-day')['href']
    link_parsed = normalize_url(link)
    word_url = resolve_url(link_parsed)
    word_doc = get_details_doc(word_url, true)

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

