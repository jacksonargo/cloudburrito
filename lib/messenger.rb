require 'slack-ruby-client'

# Class to send messages through slack
class Messenger
  @@client = nil
  def self.notify(patron, msg)
    # Configure slack
    if @@client.nil?
      Slack.configure do |config|
        config.token = Settings.auth_token
      end
      @@client = Slack::Web::Client.new
    end
    begin
      im = @@client.im_open(user: patron.user_id).channel.id
      @@client.chat_postMessage(channel: im, text: msg)
    rescue
      puts("Was not able to send slack pm message :c")
    end
  end
end
