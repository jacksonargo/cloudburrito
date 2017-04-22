# frozen_string_literal: true

require_relative 'patron'
require 'mongoid'

# Message
# A message to send to a patron.
class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :to, class_name: 'Patron'

  field :text, type: String, default: ''
  field :sent, type: Boolean, default: false
  field :sent_at, type: Time
  field :via, type: String

  def sent!
    self.sent = true
    self.sent_at = Time.now
    save
  end
end
