class TrmnlSender
  def self.send_to_trmnl(data_payload)
    trmnl_webhook_url = "https://usetrmnl.com/api/custom_plugins/#{ENV['TRMNL_PLUGIN_ID']}"

    puts('Send data to trmnl webhook')
    uri = URI(trmnl_webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['TRMNL_API_KEY']}"
    }

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = {merge_variables: data_payload}.to_json

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      current_timestamp = DateTime.now.iso8601
      puts "Tasks sent successfully to TRMNL at #{current_timestamp}"
    else
      puts "Error: #{response.body}"
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    raise
  end

end
