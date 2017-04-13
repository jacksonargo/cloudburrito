require_relative 'settings'
require 'mongoid'

## Class to store data for the participants

class Patron
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :burritos, class_name: "Package", inverse_of: :hungry_man
  has_many :deliveries, class_name: "Package", inverse_of: :delivery_man

  field :user_id, type: String
  field :_id, type: String, default: ->{ user_id }
  field :is_active, type: Boolean, default: true

  def to_s
    "<@#{user_id}>"
  end

  def is_on_delivery?
    return false unless deliveries.exists?
    return deliveries.last.delivered == false
  end

  def is_already_waiting?
    return false unless burritos.exists?
    return burritos.last.delivered == false
  end

  def time_since_last_burrito
    return updated_at unless burritos.where(delivered: true).exists?
    return Time.now - max(updated_at, burritos.where(delivered: true).last.delivery_time)
  end

  def time_since_last_delivery
    return 0 unless deliveries.where(delivered: true).exists?
    return Time.now - deliveries.where(delivered: true).last.delivery_time
  end

  def is_greedy?
    time_since_last_burrito > Settings.greedy_time
  end

  def is_sleeping?
    time_since_last_delivery > Settings.sleep_time
  end

  def time_until_hungry
    x = time_since_last_burrito - Settings.greedy_time
    0 if x < 0
  end

  def time_until_awake
    x = time_since_last_delivery - Settings.sleep_time
    0 if x < 0
  end
end
