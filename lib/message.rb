require 'mongoid'

class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :patron

  field :text, type: String
end
