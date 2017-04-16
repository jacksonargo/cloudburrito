require 'json'

# Class to access settings
class Settings

  @@verification_token = "XXX_dummy_token_XXX"
  @@auth_token = "XXX_dummy_token_XXX"
  @@greedy_time = 3600
  @@sleep_time = 3600
  @@stale_time = 300

  def self.set(data)
    return if data.class != Hash
    @@verification_token = data["verification_token"] if data["verification_token"]
    @@auth_token = data["auth_token"] if data["auth_token"]
    @@greedy_time = data["greedy_time"] if data["greedy_time"]
    @@sleep_time = data["sleep_time"] if data["sleep_time"]
    @@stale_time = data["stale_time"] if data["stale_time"]
  end

  def self.verification_token
    @@verification_token
  end
  def self.auth_token
    @@auth_token
  end
  def self.greedy_time
    @@greedy_time
  end
  def self.sleep_time
    @@sleep_time
  end
  def self.stale_time
    @@stale_time
  end
end
