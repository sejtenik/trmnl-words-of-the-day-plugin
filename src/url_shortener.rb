class UrlShortener
  def self.shorten_url_with_tinyurl(long_url)
    if long_url.length < 60 || ENV['TINYURL_API_KEY'].nil?
        return long_url
    end

    uri = URI("https://api.tinyurl.com/create")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{ENV['TINYURL_API_KEY']}"

    request.body = { url: long_url}.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data.dig("data", "tiny_url")
    else
      puts "tinyurl error: #{response.code} - #{response.body}"
      long_url
    end
  rescue => e
    puts "tinyurl error: #{e.message}"
    return long_url
  end
end