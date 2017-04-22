# frozen_string_literal: true

require_relative 'patron'
require 'mongoid'

# Package
# A burrito/delivery that has been requested.
class Package
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :hungry_man, class_name: 'Patron', inverse_of: :burritos
  belongs_to :delivery_man, class_name: 'Patron', inverse_of: :deliveries

  field :en_route, type: Boolean, default: false
  field :received, type: Boolean, default: false
  field :force_stale, type: Boolean, default: false
  field :failed, type: Boolean, default: false
  field :retry, type: Boolean, default: false
  field :assigned, type: Boolean, default: false
  field :assigned_at, type: Time
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

  # Failed packages aren't stale
  # En route packages aren't stale
  # Received packages aren't stale
  # Unassigned packages aren't stale
  def stale?
    return false if failed
    return false if en_route
    return false if received
    return false unless assigned
    time_alive > max_age || force_stale
  end

  def stale!
    self.force_stale = true
    save
  end

  def time_alive
    return Time.now - assigned_at unless assigned_at.nil?
    0
  end

  def failed?
    failed
  end

  def failed!
    self.failed = true
    save
  end

  def delivered
    self.delivery_time = Time.now
    self.received = true
    self.en_route = true
  end

  def delivered!
    delivered
    save
  end

  def delivered?
    received
  end

  def assigned?
    assigned
  end

  def assign!(dm)
    self.delivery_man = dm
    self.assigned_at = Time.now
    self.assigned = true
    save
  end
end
