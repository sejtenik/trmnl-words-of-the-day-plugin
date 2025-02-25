require 'yaml'
require 'date'

Dir.glob(File.join(__dir__, "providers/**/*.rb")).each { |file| require_relative file }
require_relative 'providers/word_of_the_day_provider'

STATE_FILE = 'providers_shuffle_state.yml'

# Generates a random permutation of all available providers and saves it to a file.
# Then, it returns the next provider, removing it from the list.
# Once the list is exhausted, a new permutation is generated.
class ProviderShuffleMachine

  def next_provider
    state = load_state

    if state[:date] != Date.today.to_s || state[:providers].empty?
      state = init_state
    end

    provider_class_name = state[:providers].shift
    puts "Using #{provider_class_name}"
    provider = Object.const_get(provider_class_name)
    save_state(state)

    provider.new
  end

  private
  def init_state
    {
      date: Date.today.to_s,
      providers: WordOfTheDayProvider.providers.map(&:name).shuffle
    }
  end

  def load_state
    if File.exist?(STATE_FILE)
      YAML.load_file(STATE_FILE)
    else
      init_state
    end
  end

  def save_state(state)
    File.open(STATE_FILE, 'w') { |file| file.write(state.to_yaml) }
  end

end
