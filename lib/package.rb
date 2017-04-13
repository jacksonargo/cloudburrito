require 'mongoid'

# Class to store data about packages

class Package
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :hungry_man, class_name: "Patron", inverse_of: :burritos
  belongs_to :delivery_man, class_name: "Patron", inverse_of: :deliveries

  field :en_route, type: Boolean, default: false
  field :delivered, type: Boolean, default: false
  field :delivery_time, type: Time
end
