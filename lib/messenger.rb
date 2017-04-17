require_relative '../cloudburrito'
require 'slack-ruby-client'

# Class to send messages through slack
class Messenger
  def self.notify(patron, msg)
    # Configure slack
    Slack.configure do |config|
      config.token = CloudBurrito.slack_auth_token
    end
    client = Slack::Web::Client.new
    # Send the message
    begin
      im = client.im_open(user: patron.user_id).channel.id
      resp = client.chat_postMessage(channel: im, text: msg)
      MessageLogger.new(patron: patron, slack_response: resp, message: msg).save
    rescue
      puts("Was not able to send slack pm message :c")
    end
  end
end
