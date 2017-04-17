require_relative '../cloudburrito'
require 'slack-ruby-client'

# Class to send messages through slack
class Messenger
  @@client = nil
  def self.notify(patron, msg)
    # Configure slack
    if @@client.nil?
      Slack.configure do |config|
        config.token = CloudBurrito.slack_auth_token
      end
      @@client = Slack::Web::Client.new
    end
    begin
      im = @@client.im_open(user: patron.user_id).channel.id
      resp = @@client.chat_postMessage(channel: im, text: msg)
      MessageLogger.new(patron: patron, slack_response: resp, message: msg).save
    rescue
      puts("Was not able to send slack pm message :c")
    end
  end
end
