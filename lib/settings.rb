# Class to access settings
class Settings

  @@greedy_time = 3600
  @@sleep_time = 3600
  @@stale_time = 300

  def self.set(data)
    return if data.class != Hash
    @@greedy_time = data["greedy_time"] if data["greedy_time"]
    @@sleep_time = data["sleep_time"] if data["sleep_time"]
    @@stale_time = data["stale_time"] if data["stale_time"]
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
