class DictionaryComParser < EnglishWordProvider
  def fetch_word
    json_data&.dig('headword')
  end

  def fetch_definitions
    data = json_data
    return {} unless data

    pronunc = (data.dig('pronunciation', 'phonetic', 'html') || '').gsub(/<[^>]+>/, '').strip
    example = (data['exampleSentence'] || '').gsub(/<[^>]+>/, '').strip

    {
      part_of_speech: data['partOfSpeech'],
      pronunciation: pronunc,
      definition: data['definition'],
      example: example,
      url: "https://www.dictionary.com/browse/#{data['slug']}"
    }
  end

  def url
    "https://www.dictionary.com/word-of-the-day"
  end

  private

  def json_data
    return @json_data if defined?(@json_data)
    script = @doc.at_css('#WordOfTheDayModal-props')
    @json_data = script ? JSON.parse(script.text) : nil
  end
end
