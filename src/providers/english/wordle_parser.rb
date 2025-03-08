class WordleParser < EnglishWordProvider

  def fetch_word
    table = @doc.at_css('table')
    rows = table.css('tbody tr')
    rows[1].css('td')[2]&.text&.strip&.downcase
  end

  def fetch_definitions
    gpt_word_provider = GptWordProvider.new
    gpt_word_provider.word = @word
    gpt_word_provider.fetch_definitions
  end

  def url
    "https://wordfinder.yourdictionary.com/wordle/answers/"
  end

  def src_desc
    "Yesterday's Wordle + gpt-4o"
  end

end
