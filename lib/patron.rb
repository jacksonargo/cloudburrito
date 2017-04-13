require 'mongoid'

## Class to store data for the participants

class Patron
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :is_active, type: Boolean, default: true
  field :is_on_delivery, type: Boolean, default: false
  field :is_hungry, type: Boolean, default: false
  field :last_feeding, type: Time, default: Time.now
  field :last_delivery, type: Time, default: Time.now
  field :total_feedings, type: Integer, default: 0
  field :total_deliveries, type: Integer, default: 0
  field :_id, type: String, default: ->{ user_id }

  def to_s
    "<@#{user_id}>"
  end
end
