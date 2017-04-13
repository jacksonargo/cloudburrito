require 'slack-ruby-client'

# Class to send messages through slack
class Messenger
  # Configure slack
  Slack.configure do |config|
    config.token = Settings.auth_token
  end

  @@client = Slack::Web::Client.new
  def self.notify(patron, msg)
    return if true
    im = @@client.im_open(user: patron.user_id).channel.id
    @@client.chat_postMessage(channel: im, text: msg)
  end
end
