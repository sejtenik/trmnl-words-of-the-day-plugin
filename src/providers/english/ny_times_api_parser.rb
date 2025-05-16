require_relative '../../gpt_tool'

#To use this parser, you need to get an API key from https://developer.nytimes.com/
# and set it in the environment variable NYTIMES_API_KEY.
# You need to configure OPENAI_API_KEY as well since NYTimes api doesn't provide full word definition.
class NYTimesApiParser < EnglishWordProvider

  def get_doc
    date = Date.today.strftime("%Y%m%d")
    keyword = "Word of the day"
    prep_url = url + "?fq=desk:Learning&begin_date=#{date}&q=\"#{keyword}\"&api-key=#{ENV['NYTIMES_API_KEY']}"
    get_details_doc(prep_url)
  end

  def fetch_word
    articles = @doc["response"]["docs"]

    unless articles&.empty?
      articles.first["headline"]["main"].split(':')[1].strip
    end
  end

  def fetch_definitions
    link = @doc["response"]["docs"].first["web_url"]

    GptTool.new.full_word_definition(@word).merge(url: link)
  end

  def url
    "https://api.nytimes.com/svc/search/v2/articlesearch.json"
  end

  def src_desc
    "New York Times + gpt-4o"
  end

  def may_be_enhanced?
    false
  end

end
