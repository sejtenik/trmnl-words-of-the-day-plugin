require 'net/imap'
require 'mail'

#To use this parser, you need to:
# - have an email with IMAP support (presumably different from your regular email account)
# - create an account on https://www.vocabulary.com/ using the same email
# - subscribe to the "Word of the Day" newsletter https://www.vocabulary.com/word-of-the-day/
# - set the following environment variables in .env file:
#   EMAIL_HOST
#   EMAIL_LOGIN
#   EMAIL_PASSWORD
class VocabularyParser < EnglishWordProvider

  KEYWORD = 'Word of the Day'
  SENDER = 'reply@email.vocabulary.com'

  def get_doc
    imap = Net::IMAP.new(ENV['EMAIL_HOST'], port: 993, ssl: true)
    imap.login(ENV['EMAIL_LOGIN'], ENV['EMAIL_PASSWORD'])
    imap.select('INBOX')

    uids = imap.uid_search(['FROM', SENDER, 'SUBJECT', KEYWORD])

    matching_messages = uids.map do |uid|
      envelope = imap.uid_fetch(uid, 'ENVELOPE')[0].attr['ENVELOPE']
      { uid: uid, date: envelope.date, subject: envelope.subject }
    end.select { |msg| msg[:subject].start_with?(KEYWORD) }

    sorted_messages = matching_messages.sort_by { |msg| Date.parse(msg[:date]) }.reverse

    unless sorted_messages.any?
      return
    end

    latest_uid = sorted_messages.first[:uid]
    envelope = imap.uid_fetch(latest_uid, 'ENVELOPE')[0].attr['ENVELOPE']
    @word_from_title = envelope.subject.split(':')[1].strip
    msg = imap.uid_fetch(latest_uid, 'RFC822')[0].attr['RFC822']
    imap.store(latest_uid, "+FLAGS", [:Seen])
    mail = Mail.read_from_string(msg)
    html_body = mail.html_part ? mail.html_part.decoded : mail.body.decoded
    return Nokogiri::HTML(html_body)
  rescue Net::IMAP::ByeResponseError
    puts 'ByeResponseError'
  rescue Net::IMAP::Error => e
    puts "IMAP ERROR: #{e.message}"
  ensure
    imap.disconnect unless imap.disconnected?
  end

  def fetch_word
    @word_from_title
  end

  def fetch_definitions
    preheader_div = @doc.at_css('div.preheader')
    definition_text = preheader_div.inner_html.sub(/^.*?VocabTrainer\.\s*/i, '')
    link_tag = @doc.css('a').find { |a| a&.text&.strip&.downcase == @word.downcase }
    link = link_tag&.[]('href')

    {
      definition: definition_text,
      url: link
    }
  end

  def url
    "https://www.vocabulary.com/word-of-the-day/"
  end
end
