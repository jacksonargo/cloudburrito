# frozen_string_literal: true

require_relative 'package'
require_relative 'message'
require_relative 'pool'
require_relative '../lib/slack_client'
require_relative '../lib/cloudburrito_logger'
require 'mongoid'

# Patron
# A cloudburrito user and volunteer.
class Patron
  include Mongoid::Document
  include Mongoid::Timestamps
  include CloudBurritoLogger
  include SlackClient

  has_many :burritos, class_name: 'Package', inverse_of: :hungry_man
  has_many :deliveries, class_name: 'Package', inverse_of: :delivery_man
  has_many :messages, inverse_of: :to
  belongs_to :pool

  field :active, type: Boolean, default: false
  field :active_at, type: Time
  field :inactive_at, type: Time
  field :force_not_greedy, type: Boolean, default: false
  field :force_not_sleepy, type: Boolean, default: false
  field :user_token, type: String, default: -> { rand(1 << 256).to_s(36) }
  field :sleepy_time, type: Integer, default: 3600
  field :greedy_time, type: Integer, default: 3600
  field :slack_user,  type: Boolean, default: true
  field :slack_user_id, type: String

  before_create do |patron|
    patron.active_at ||= Time.now if patron.active
  end

  validates :sleepy_time, numericality: true
  validates :greedy_time, numericality: true
  validates :slack_user_id, presence: true, if: :slack_user

  def to_s
    _id.to_s
  end

  def active!
    self.active_at = Time.now
    self.active = true
    save
  end

  def active?
    active
  end

  def inactive!
    self.inactive_at = Time.now
    self.active = false
    save
  end

  def inactive?
    !active
  end

  def active_delivery
    deliveries.where(failed: false, received: false).last
  end

  def on_delivery?
    active_delivery != nil
  end

  def incoming_burrito
    burritos.where(failed: false, received: false).last
  end

  def waiting?
    incoming_burrito != nil
  end

  def time_of_last_burrito
    return Time.at(0) unless burritos.where(received: true).exists?
    burritos.where(received: true).last.received_at
  end

  def time_of_last_delivery
    return Time.at(0) unless deliveries.where(received: true).exists?
    deliveries.where(received: true).last.received_at
  end

  def greedy?
    return false if force_not_greedy
    return true if inactive?
    time_until_hungry.positive?
  end

  def sleepy?
    return false if force_not_sleepy
    time_until_awake.positive?
  end

  def time_since_last_burrito
    Time.now - time_of_last_burrito
  end

  def time_since_last_delivery
    Time.now - time_of_last_delivery
  end

  def time_since_active
    if active_at.nil?
      time_since_active = 0
    else
      time_since_active = Time.now - active_at
    end
  end

  # Time until hungry restarts whenever 
  # 1) you become active
  # 2) receive a burrito
  def time_until_hungry
    if time_since_last_burrito < time_since_active
      time_since_recent_action = time_since_last_burrito
    else
      time_since_recent_action = time_since_active
    end

    x = greedy_time - time_since_recent_action.to_i
    x > 0 ? x : 0
  end

  def time_until_awake
    x = sleepy_time - time_since_last_delivery.to_i
    x > 0 ? x : 0
  end

  # Select delivery man based on these rules:
  # 1) Must be active (per above)
  # 2) Must not be on a delivery
  # 3) Cannot be selected more than once per sleep time
  # 4) You cannot deliver to yourself
  def can_deliver?
    return false if inactive?
    return false if on_delivery?
    return false if sleepy?
    return false if waiting?
    true
  end

  def new_token
    rand(1 << 256).to_s(36)
  end

  def reset_token
    self.user_token = new_token
    save
  end

  def stats_url
    reset_token
    "https://cloudburrito.us/user?id=#{_id}&token=#{user_token}"
  end

  def name
    x = slack_user_info
    return x.user.profile.first_name unless x.nil?
    _id
  end

  def slack_link
    "<@#{slack_user_id}>"
  end

  def slack_user_info
    return {} unless slack_user
    begin
      slack_client.users_info(user: slack_user_id)['user']
    rescue
      logger.error "Failed to load slack user info for #{slack_user_id}"
      {}
    end
  end

  def slack_first_name
    info = slack_user_info
    if info != {}
      info['profile']['first_name']
    else
      slack_user_id
    end
  end
end
