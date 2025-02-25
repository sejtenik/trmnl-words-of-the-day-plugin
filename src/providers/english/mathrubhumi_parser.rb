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

