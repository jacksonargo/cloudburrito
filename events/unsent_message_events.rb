# frozen_string_literal: true

require_relative '../models/message'
require_relative '../models/lock'
require_relative '../lib/events'
require_relative '../lib/cloudburrito_logger'
require_relative '../lib/slack_client'
require 'slack-ruby-client'
require 'yaml'

# UnsentMessageEvents
# A class to send new messages to users
class UnsentMessageEvents < Events

  include CloudBurritoLogger
  include SlackClient

  def unsent_messages
    Message.where(sent: false)
  end

  def send_slack_pm(msg)
    # Don't pm when we are testing
    if ENV['RACK_ENV'] == 'test'
      logger.info "Not sending slack pm in test environment."
      return true
    end
    begin
      im = slack_client.im_open(user: msg.to._id).channel.id
      slack_client.chat_postMessage(channel: im, text: msg.text)
      logger.info "Sent slack pm to #{msg.to}."
      true
    rescue
      logger.error "Failed to send slack pm to #{msg.to}."
      false
    end
  end

  def send_next
    # Do nothing unless there are messages to send
    return unless unsent_messages.exists?
    # Do nothing if we can't create the lock
    return if Lock.where(event: self.class.to_s).exists?
    # Create the lock
    Lock.create event: self.class.to_s
    # Get the first unsent message
    msg = unsent_messages.first
    # Send it
    logger.info "Sending message #{msg._id} for #{msg.to}."
    send_slack_pm msg
    # Mark sent
    msg.sent!
    # Release the lock
    Lock.where(event: self.class.to_s).delete
  end

  def wait_for_complete
    while unsent_messages.exists?
    end
  end

  def next_action
    while unsent_messages.exists? do
      send_next
    end
    sleep 0.1
  end
end
