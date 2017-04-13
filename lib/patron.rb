require 'mongoid'

## Class to store data for the participants

class Patron
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :burritos, class_name: "Package", inverse_of: :hungry_man
  has_many :deliveries, class_name: "Package", inverse_of: :delivery_man

  field :user_id, type: String
  field :_id, type: String, default: ->{ user_id }
  field :is_active, type: Boolean, default: true
  field :is_on_delivery, type: Boolean, default: false
  field :is_hungry, type: Boolean, default: false

  def to_s
    "<@#{user_id}>"
  end
end
