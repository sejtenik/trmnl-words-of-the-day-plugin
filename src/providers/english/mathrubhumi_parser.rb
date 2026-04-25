class MathrubhumiParser < EnglishWordProvider

  def fetch_word
    @link = get_link

    @link.text.strip.match(/.*:.{2}(.*)/)[1].chop
  end

  def fetch_definitions
    link = @link['href']

    @word_doc = get_details_doc(link)

    pron_p = @word_doc.xpath('//p[contains(., "Pronunciation:")]').first&.text
    pronunciation = pron_p&.split('Pronunciation:')&.last&.strip

    meaning_header = @word_doc.at('p strong:contains("Meaning:")')
    meaning = meaning_header&.parent&.children&.map(&:text)&.drop(1)&.join&.strip

    example_p = @word_doc.at('p strong:contains("Example")')&.parent
    example_items = example_p&.xpath('following-sibling::ul[1]')&.css('li')
    example = example_items&.map { |li| li.text.strip }&.first

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
    @doc.at_xpath('//a[contains(translate(text(), "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"), "word of the day")]')
  end

end
