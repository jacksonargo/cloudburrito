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

  field :retry, type: Boolean, default: false
  field :force_stale, type: Boolean, default: false
  field :failed, type: Boolean, default: false
  field :failed_at, type: Time
  field :assigned, type: Boolean, default: false
  field :assigned_at, type: Time
  field :en_route, type: Boolean, default: false
  field :en_route_at, type: Time
  field :received, type: Boolean, default: false
  field :received_at, type: Time
  field :max_age, type: Integer, default: 300 # 5 minutes
  field :slack_params, type: Hash

  after_initialize do |package|
    package.delivery_man ||= package.hungry_man
  end

  before_create do |package|
    package.received_at ||= Time.now if package.received
    package.en_route_at ||= Time.now if package.en_route
    package.assigned_at ||= Time.now if package.assigned
    package.failed_at   ||= Time.now if package.failed
  end

  validates :received, exclusion: { in: [true] }, if: :failed?
  validates :failed, exclusion: { in: [true] }, if: :received?

  def latency
    if failed
      0 if failed_at.nil?
      failed_at - created_at
    elsif received
      0 if received_at.nil?
      received_at - created_at
    else
      Time.now - created_at
    end
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
    self.failed_at = Time.now
    self.failed = true
    save
  end

  def received!
    en_route! unless en_route?
    self.received_at = Time.now
    self.received = true
    save
  end

  def received?
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

  def en_route?
    en_route
  end

  def en_route!
    self.en_route_at = Time.now
    self.en_route = true
    save
  end

  def lost?
    assigned && Time.now - assigned_at > 3600 && !received && !failed
  end
end
