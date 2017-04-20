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
  field :assigned, type: Boolean, default: false
  field :delivery_time, type: Time
  field :max_age, type: Integer, default: 300 # 5 minutes
  field :slack_params, type: Hash

  after_initialize do |package|
    package.delivery_man ||= package.hungry_man
    package.save
  end

  def latency_time
    delivery_time - created_at
  end

  def to_s
    _id.to_s
  end

  def stale?
    return false if failed
    return false if received
    time_alive > max_age or force_stale
  end

  def stale!
    self.force_stale = true
    self.save
  end

  def time_alive
    Time.now - created_at
  end

  def failed?
    failed
  end

  def failed!
    self.failed = true
    self.save
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

  def assigned?
    self.assigned
  end 

  def assign!(dm)
    self.delivery_man = dm
    self.assigned = true
    self.save
  end
end
