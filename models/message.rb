require_relative 'patron'
require 'mongoid'

class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :to, class_name: "Patron"

  field :text, type: String, default: ''
  field :sent, type: Boolean, default: false
  field :sent_at, type: Time
  field :via, type: String

  def sent!
    self.sent = true
    self.sent_at = Time.now
    self.save
  end
end
