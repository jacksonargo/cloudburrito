# frozen_string_literal: true

require 'mongoid'

# Locker
# Used to create locks on models
class Locker
  include Mongoid::Document

  # Tries to create a lock for the model.
  # If the lock exist, then Mongoid will through an expection
  # Otherwise we create it and return true
  def self.lock(model)
    begin
      self.create _id: model.class.to_s + model._id.to_s
      true
    rescue
      false
    end
  end

  # Removes a lock
  # If the lock does not exist, Mongoid will throw an exception
  # Otherwise return true
  def self.unlock(model)
    begin
      self.find(model.class.to_s + model._id.to_s).delete
      true
    rescue
      false
    end
  end
end
