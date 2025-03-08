class NYTimesParser < EnglishWordProvider

  def fetch_word
    word_link = @doc.at_css('a:has(h3:contains("Word of the Day"))').text.strip
    word_link.split(':').last.strip
  end

  def fetch_definitions

    link = 'https://www.nytimes.com' + @doc.at_css('a:has(h3:contains("Word of the Day"))')['href']

    @word_doc = get_details_doc(link, true)

    h2 = @word_doc.at_css("h2:contains('#{@word}')")
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

