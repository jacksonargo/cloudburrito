require_relative '../cloudburrito'
require 'slack-ruby-client'

# Class to send messages through slack
class Messenger

  def self.make_slack_client
    Slack.configure do |config|
      config.token = CloudBurrito.slack_auth_token
    end
    Slack::Web::Client.new
  end

  def self.notify(patron, msg)
    client = make_slack_client
    # Send the message
    begin
      im = client.im_open(user: patron.user_id).channel.id
      resp = client.chat_postMessage(channel: im, text: msg)
      MessageLogger.new(patron: patron, slack_response: resp, message: msg).save
    rescue
      puts("Was not able to send slack pm message :c")
    end
  end

  def self.user_info(patron)
    client = make_slack_client
    client.users_info(user: patron.user_id)
  end
end
