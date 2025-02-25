require 'dotenv/load'
require_relative 'provider_shuffle_machine'
require_relative 'trmnl_sender'

word_of_the_day = nil
shuffleMachine = ProviderShuffleMachine.new
error = false

loop do
  provider = shuffleMachine.next_provider
  begin
    word_of_the_day = provider.fetch
    break if word_of_the_day
  rescue StandardError => e
    puts "Error: #{e.class} - #{e.message}"
    error = true
  end
end

if error
  #let's indicate that there was an error - to check logs later
  word_of_the_day[:source] += '!'
end

puts word_of_the_day
TrmnlSender.send_to_trmnl(word_of_the_day)
