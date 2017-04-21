require_relative 'patron'
require 'mongoid'

class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :to, class_name: "Patron"

  field :text, type: String
end
