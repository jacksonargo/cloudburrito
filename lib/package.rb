require 'mongoid'

# Class to store data about packages

class Package
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :hungry_man, class_name: "Patron", inverse_of: :burritos
  belongs_to :delivery_man, class_name: "Patron", inverse_of: :deliveries
end
