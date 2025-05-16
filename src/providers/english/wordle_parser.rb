require_relative '../../gpt_tool'

class WordleParser < EnglishWordProvider

  def fetch_word
    table = @doc.at_css('table')
    rows = table.css('tbody tr')
    rows[1].css('td')[2]&.text&.strip&.downcase
  end

  def fetch_definitions
    GptTool.new.full_word_definition(@word)
  end

  def url
    "https://wordfinder.yourdictionary.com/wordle/answers/"
  end

  def src_desc
    "Yesterday's Wordle + gpt-4o"
  end

  def may_be_enhanced?
    false
  end

end
