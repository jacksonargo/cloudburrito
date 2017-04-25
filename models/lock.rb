# frozen_string_literal: true

require 'mongoid'

# Lock
# An event lock
class Lock
  include Mongoid::Document
  field :event
  field :_id, default: -> { event }
end
