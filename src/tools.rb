class Tools
  def self.nvl(string, default)
    string.nil? || string.empty? ? default : string
  end

  def self.remove_accents(text)
  text.unicode_normalize(:nfd).gsub(/\p{Mn}/, '')
  end
end