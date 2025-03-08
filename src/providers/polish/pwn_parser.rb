class PwnParser < PolishWordProvider
  def fetch_word
    day_word_box = @doc.at_css(".sjp-slowo-dnia")
    word_link = day_word_box.at_css("a")
    word_link.text.strip
  end

  def fetch_definitions
    day_word_box = @doc.at_css(".sjp-slowo-dnia")
    word_link = day_word_box.at_css("a")

    word_url = word_link['href']
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
