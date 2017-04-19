require 'mongoid'

# Class to store data about packages

class Package
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :hungry_man, class_name: "Patron", inverse_of: :burritos
  belongs_to :delivery_man, class_name: "Patron", inverse_of: :deliveries

  field :en_route, type: Boolean, default: false
  field :received, type: Boolean, default: false
  field :force_stale, type: Boolean, default: false
  field :failed, type: Boolean, default: false
  field :retry, type: Boolean, default: false
  field :delivery_time, type: Time
  field :max_age, type: Integer, default: 300 # 5 minutes

  def to_s
    _id.to_s
  end

  def is_stale?
    time_alive > max_age or force_stale
  end

  def time_alive
    Time.now - created_at
  end

  def delivered
    self.delivery_time = Time.now
    self.received = true
    self.en_route = true
  end

  def delivered!
    delivered
    self.save
  end

  def delivered?
    received
  end
end
