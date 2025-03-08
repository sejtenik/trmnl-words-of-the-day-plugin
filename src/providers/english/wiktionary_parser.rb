class WiktionaryParser < EnglishWordProvider
  def fetch_word
    word_element = @doc.at_css("#WOTD-rss-title")
    word_element&.text&.strip
  end

  def fetch_definitions
    word_element = @doc.at_css("#WOTD-rss-title")
    part_of_speech = word_element.parent.parent.next_element&.text&.strip
    definition = @doc.at_css("#WOTD-rss-description ol li")&.text&.strip&.gsub(/^\([^\)]+\)\s*/, '')&.strip

    link = word_element.parent['href']
    link = resolve_url(link)
    @word_doc = get_details_doc(link)
    pronunciation = @word_doc.at_css('span.IPA')&.text&.strip&.gsub!(/^\//, '')&.gsub!(/\/$/, '')&.strip

    first_example = @word_doc.css('dd div.h-usage-example i.e-example')&.first&.text&.strip

    {
      definition: definition,
      part_of_speech: map_part_of_speech(part_of_speech),
      pronunciation: pronunciation,
      example: first_example,
      url: link
    }
  end

  def url
    "https://en.wiktionary.org/wiki/Wiktionary:Main_Page"
  end

  private
  def map_part_of_speech(part_of_speech)
    case part_of_speech
    when 'n' then 'noun'
    when 'proper n' then 'noun'
    when 'v' then 'verb'
    when 'adj' then 'adjective'
    when 'adv' then 'adverb'
      else part_of_speech
    end
  end

end

