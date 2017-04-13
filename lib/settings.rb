require 'json'

# Class to access settings
class Settings
  data = JSON::parse File.read("config/settings.json")
  @@verification_token = data["verification_token"]
  @@auth_token = data["auth_token"]
  @@greedy_time = data["greedy_time"]
  @@greedy_time ||= 3600
  @@sleep_time = data["sleep_time"]
  @@sleep_time ||= 3600

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
end
