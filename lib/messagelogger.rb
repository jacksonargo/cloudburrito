require 'mongoid'

# Class to log each message sent from the bot

class MessageLogger
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :patron

  field :message, type: String
  field :slack_response, type: Hash
end
