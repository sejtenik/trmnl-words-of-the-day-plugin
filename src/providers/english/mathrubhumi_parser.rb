class MathrubhumiParser < EnglishWordProvider

  def fetch_word
    @link = get_link

    @link.text.strip.match(/.*:.{2}(.*)/)[1].chop
  end

  def fetch_definitions
    link = @link['href']

    @word_doc = get_details_doc(link)

    pron_line = @doc.at('p strong:contains("Pronunciation")')&.parent&.text
    pronunciation = pron_line&.split(':')&.last&.strip

    meaning_header = @doc.at('p strong:contains("Meaning")')
    meaning = meaning_header&.parent&.children&.map(&:text)&.drop(1)&.join&.strip

    example_items = @doc.css('p strong:contains("Examples") ~ ul').first&.css('li')
    example = example_items&.map { |li| li.text.strip }

    {
      definition: meaning,
      url: link,
      pronunciation: pronunciation,
      example: example,
    }
  end

  def url
    "https://english.mathrubhumi.com/topics/tag/word_of_the_day"
  end

  private

  def get_link
    @doc.at_xpath('//a[contains(text(), "Word of the Day")]')
  end

end

