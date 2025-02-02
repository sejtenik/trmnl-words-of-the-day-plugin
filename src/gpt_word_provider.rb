require 'openai'
require 'json'
require_relative 'word_of_the_day_provider'
require_relative 'english_word_provider'

# For this provider, I decided to rely on conventional online dictionaries for selecting the Word of the Day.
# The GPT model, however, is tasked with generating the definition and other attributes.
class GptWordProvider < WordOfTheDayProvider

  def initialize
    init_random_english_word_provider
  end

  def fetch_word(_)
    doc = @provider.get_doc
    @provider.fetch_word(doc)
  end

  def fetch_definitions(_, word)
    gpt_response = gpt_client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: build_definitions_prompt(word) }
        ],
        temperature: 0.1,
        max_tokens: 300
      }
    )

    model_result = gpt_response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(model_result, symbolize_names: true)
    puts JSON.pretty_generate(parsed)
    parsed
  end

  def src_desc
    "GPT3.5-turbo@#{@provider.src_desc.sub(/^www\./, '')}"
  end

  def get_doc
    ''
  end

  private

  def init_random_english_word_provider
    @provider = WordOfTheDayProvider.providers
                                    .select { |klass|
                                      klass < EnglishWordProvider
                                    }.sample.new
  end

  def gpt_client
    OpenAI::Client.new(
    access_token: ENV['OPENAI_API_KEY'],
    log_errors: true)
  end

  def build_definitions_prompt(word)
    <<~PROMPT
      Provide the following information about the word "#{word}":
      1. An English definition in one or at most two sentences.
      2. Its pronunciation in IPA format. Use the standard IPA transcription as defined in the Oxford English Dictionary. For example, for "cat", use "kæt". 
      3. Its part of speech (e.g., noun, verb, adjective, etc.).
      4. An example sentence in English using the word.
      5. A one- or two-word translation of the word into Polish in the context of the given definition and example.
      6. The difficulty level of the word according to the following scale:
         - A1 (Beginner): very basic expressions, ability to introduce oneself and describe simple situations.
         - A2 (Pre-Intermediate): basic information and simple conversations about personal life.
         - B1 (Intermediate): understanding everyday topics and communicating during travel.
         - B2 (Upper-Intermediate): fluent conversation, clear discussions, and well-structured written expression.
         - C1 (Advanced): comprehension of complex texts, ability to detect irony and subtle meanings.
         - C2 (Proficient): mastery in speaking and writing, with fluid and precise expression.
         Choose only one option as a two-character code (e.g., "A1", "B2").
      Answer in proper JSON format with the following keys: "definition", "pronunciation", "part_of_speech", "example", "meaning", "level".
      Answer should start and end with curly braces. 
    PROMPT
  end

end