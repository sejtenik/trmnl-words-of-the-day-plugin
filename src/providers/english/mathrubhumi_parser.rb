class MathrubhumiParser < EnglishWordProvider

  def fetch_word
    link = link1

    unless link.nil?
      return link.at_xpath('h1')&.text[/'.*?'/]&.delete("'")&.strip&.downcase
    end

    link = link2

    link.text.strip.match(/.*:.{2}(.*)/)[1].chop
  end

  def fetch_definitions
    link = (link1.nil? ? link2['href'] : 'https://english.mathrubhumi.com' + link1['href'])

    @word_doc = get_details_doc(link)

    divs = @word_doc.css('div.mpp-story-content-details-main.my-3, div.article-body')

    meaning = nil
    example = nil
    pronunciation = nil
    part_of_speech = nil

    divs.each_with_index do |div, index|
      case div.at_css('p strong')&.text
      when 'Meaning'
        meaning = divs[index + 1]&.at_css('p')&.text&.strip
      when 'Pronunciation'
        pronunciation = divs[index + 1]&.at_css('p')&.text&.strip
        if pronunciation&.include?('/')
          pronunciation = pronunciation[/\/(.*?)\//, 1]
        end
      when 'Examples from books and articles'
        example = divs[index + 1]&.at_css('li')&.text&.strip
      end
    end

    if meaning.nil?
      pronunciation = @word_doc.at_xpath("//p[strong[contains(text(), 'Pronunciation:')]]")&.text&.sub('Pronunciation:', '')&.strip

      meaning_node = @word_doc.at_xpath("//p[strong[contains(text(), 'Meaning:')]]/following-sibling::p[1]")
      meaning = meaning_node&.text&.strip

      part_of_speech = meaning[/\b(noun|verb|adjective|adverb)\b/i]&.downcase

      example_node = @word_doc.at_xpath("//p[strong[contains(text(), 'Examples from Literature:')]]/following-sibling::p[1]")
      example = example_node&.text&.strip

    end

    {
      definition: meaning,
      url: link,
      pronunciation: pronunciation,
      example: example,
      part_of_speech: part_of_speech
    }
  end

  def url
    "https://english.mathrubhumi.com/topics/tag/word_of_the_day"
  end

  private

  def link2
    @doc.at_xpath('//a[contains(text(), "Word of the Day")]')
  end

  def link1
    @doc.at_xpath('//a[h1[contains(text(), "Word of the day")]]')
  end
end

