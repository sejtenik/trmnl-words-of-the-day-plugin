class PwnParser < PolishWordProvider
  def fetch_word
    label_div = @doc.at_xpath('//div[contains(text(), "Słowo dnia")]')
    container = label_div.parent
    container.at_css('.typography-serif-2xl')&.text&.strip
  end

  def fetch_definitions
    label_div = @doc.at_xpath('//div[contains(text(), "Słowo dnia")]')
    container = label_div.parent
    relative_url = container.at_css('a[href*="/slowniki/"]')&.[]('href')
    word_url = "#{url}#{relative_url}"
    @word_doc = get_details_doc(word_url)
    definition_text = @word_doc.text.match(/«(.*?)»/)
    definition = definition_text[1]&.strip

    {
      definition: definition,
      url: word_url
    }
  end

  def url
    "https://sjp.pwn.pl"
  end

end
