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

