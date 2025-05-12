require 'openai'
require 'json'
require_relative '../word_of_the_day_provider'
#require_relative '../english_word_provider'

# For this provider, I decided to rely on conventional online dictionaries for selecting the Word of the Day.
# The GPT model, however, is tasked with generating the definition and other attributes.
class GptWordProvider < WordOfTheDayProvider
  attr_writer :word

  def initialize
    init_random_english_word_provider
  end

  def fetch_word
    doc = @provider.get_doc
    @provider.doc = doc
    @provider.fetch_word
  end

  def fetch_definitions
    gpt_response = gpt_client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: build_definitions_prompt(@word) }
        ],
        temperature: 0.1,
        max_tokens: 300,
        response_format: { "type": "json_object" }
      }
    )

    model_result = gpt_response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(model_result, symbolize_names: true)
    puts JSON.pretty_generate(parsed)

    unless parsed[:definition]
      puts "No definition from model: #{parsed}"
      return fetch_original_definition(@word)
    end

    parsed[:url] = @provider.url

    parsed
  rescue => e
    puts e
    fetch_original_definition(@word)
  end

  def src_desc
    "GPT4o@#{@provider.src_desc.sub(/^www\./, '')}"
  end

  def get_doc
    ''
  end

  private

  def fetch_original_definition(word)
    #fallback to original definition
    orig_doc = @provider.get_doc
    definition = @provider.fetch_definitions(orig_doc, @word)
    definition.merge(source: '*' + @provider.src_desc) #To indicate an exception for further analysis
  end

  def init_random_english_word_provider
    skip_parsers = ENV['SKIP_PARSERS']&.split(',') || []  #TODO fix code duplication with ProviderShuffleMachine
    @provider = WordOfTheDayProvider.providers
                                    .select { |klass|
                                      klass < EnglishWordProvider
                                    }
                                    .reject { |provider|
                                      skip_parsers.include?(provider.to_s)
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
    5. A translation of the word into Polish that accurately reflects its most common meaning in context and matches the part of speech specified in (3). The translation may consist of more than one or two words if necessary.
    6. The difficulty level of the word according to the following scale:
       - A1 (Beginner): very basic expressions, ability to introduce oneself and describe simple situations.
       - A2 (Pre-Intermediate): basic information and simple conversations about personal life.
       - B1 (Intermediate): understanding everyday topics and communicating during travel.
       - B2 (Upper-Intermediate): fluent conversation, clear discussions, and well-structured written expression.
       - C1 (Advanced): comprehension of complex texts, ability to detect irony and subtle meanings.
       - C2 (Proficient): mastery in speaking and writing, with fluid and precise expression.
       Choose only one option as a two-character code (e.g., "A1", "B2").

    If "#{word}" is unknown, return exactly {} (no extra text, formatting, or newlines, no markdown).
    Otherwise, return a valid JSON object with the keys "definition", "pronunciation", "part_of_speech", "example", "meaning", and "level". The response must start and end with curly braces.
    Return only JSON in your response. Do not include any code blocks or other text.
  PROMPT
  end
end