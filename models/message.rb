# frozen_string_literal: true

require_relative 'patron'
require_relative '../lib/slack_client'
require_relative '../lib/cloudburrito_logger'
require 'mongoid'
require 'typhoeus'

# Message
# A message to send to a patron.
class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  include CloudBurritoLogger
  include SlackClient

  belongs_to :to, class_name: 'Patron'

  field :text, type: String, default: ''
  field :sent, type: Boolean, default: false
  field :sent_at, type: Time
  field :via, type: String
  field :response_url, type: String
  field :response_type, type: String, default: 'ephemeral'

  def sent!
    self.sent = true
    self.sent_at = Time.now
    save
  end

  # Sends the message
  def send_message
    case via
    when 'slack_dm'
      send_slack_dm_message
    when 'slack_url'
      send_slack_url_message
    else
      logger.info "No method for sending message #{_id}."
    end
    sent!
  end

  # Send message via slack dm
  def send_slack_dm_message
    # Don't dm when we are testing
    if ENV['RACK_ENV'] == 'test'
      logger.info "Not sending slack pm in test environment."
      return true
    end
    begin
      im = slack_client.im_open(user: to._id).channel.id
      slack_client.chat_postMessage(channel: im, text: text)
      logger.info "Sent slack pm to #{to}."
      true
    rescue
      logger.error "Failed to send slack pm to #{to}."
      false
    end
  end

  # Send message via slack url
  def send_slack_url_message
    headers = { 'Content-Type': 'application/json' }
    payload = { response_type: response_type, text: text }
    logger.info "Sent slack url response to #{to}."
    Typhoeus.post(response_url, headers: headers, body: payload)
  end
end
