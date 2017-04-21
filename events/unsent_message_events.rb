require_relative '../models/message'
require_relative '../lib/events'
require 'slack-ruby-client'

class UnsentMessageEvents < Events
  attr_reader :slack_client

  def initialize
    Slack.configure do |config|
      config.token = CloudBurrito.slack_auth_token
    end
    @slack_client = Slack::Web::Client.new
  end

  def unsent_messages 
    Message.where(sent: false)
  end

  def send_slack_pm(msg)
    begin
      im = @slack_client.im_open(user: msg.to._id).channel.id
      resp = @slack_client.chat_postMessage(channel: im, text: msg.text)
    rescue
      puts("Was not able to send slack pm message :c")
    end
    true
  end

  def send_next
    # Do nothing unless there are messages to send
    return unless unsent_messages.exists?
    # Get the first unsent message
    msg = unsent_messages.first
    # Send it
    send_slack_pm msg
    # Mark sent
    msg.sent!
  end

  def wait_for_complete
    while unsent_messages.exists?
    end
  end

  def next_action
    send_next
  end
end
