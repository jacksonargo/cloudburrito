require 'mongoid'

# Class to log each incoming request

class RequestLogger
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :patron

  field :params, type: Hash
  field :method, type: String
  field :uri, type: String
  field :controller_action, type: Symbol
  field :response, type: String
end
