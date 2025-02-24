require 'dotenv/load'
require_relative 'english_word_provider'
require_relative 'polish_word_provider'
require_relative 'gpt_word_provider' if ENV['OPENAI_API_KEY']
require_relative 'trmnl_sender'
require_relative 'provider_shuffle_machine'

word_of_the_day = nil
shuffleMachine = ProviderShuffleMachine.new

loop do
  provider = shuffleMachine.next_provider
  begin
    word_of_the_day = provider.fetch
    break if word_of_the_day
  rescue StandardError => e
    puts "Error: #{e.class} - #{e.message}"
  end
end

puts word_of_the_day
TrmnlSender.send_to_trmnl(word_of_the_day)
