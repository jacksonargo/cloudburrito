require_relative 'patron'
require_relative 'package'
require_relative 'settings'
require_relative 'messenger'

class Controller

  # Find the next available delivery man
  def self.get_next_delivery_man_for(hungry_man)
    # Get all the active patrons
    candidates = Patron.where(is_active: true)
    # Check that there are active patrons
    return nil unless candidates.exists?
    # Select delivery man based on these rules:
    # 1) Must be active
    # 2) Must no be on a delivery
    # 3) Cannot be selected more than once per sleep time
    candidates = candidates.each.select do |p|
      not (p.is_on_delivery? or p.is_sleeping? or p == hungry_man)
    end
    # Check if any patrons match the criteria
    return nil unless candidates.count > 0
    # Pick a random
    candidates.sample
  end

  # Create a package and send it on its way
  def self.send_on_delivery(delivery_man, hungry_man)
    # Create the new package
    package = Package.new
    package.delivery_man = delivery_man
    package.hungry_man = hungry_man
    package.save
    # Notify delivery man of his duties
    msg = "You've been volunteered to get a burrito for #{hungry_man}. "
    msg += "Please ACK this request by replying:\n/cloudburrito en route"
    Messenger.notify delivery_man, msg
    # Start a new thread to verify package delivery
    Thread.new { verify_en_route package }
  end

  # Verify that a burrito is headed to hungry man
  def self.verify_en_route(package)
    hungry_man = package.hungry_man
    delivery_man = package.delivery_man
    # Loop until the package is en route or stale
    puts "Waiting for ack..."
    until (package.en_route or package.is_stale?) do
      package.reload
    end
    unless package.en_route
      # Mark the delivery_man inactive
      puts "Delivery man took to long; finding another."
      delivery_man.is_active = false
      delivery_man.save
      msg = "You've been bounced out of the pool. Use this command "
      msg += "to rejoin the pool and start downloading burritos:\n"
      msg += "/cloudburrito join"
      Messenger.notify delivery_man, msg
      # Mark the package as failed
      puts "Package is failed."
      package.failed = true
      package.save
      # Try to find a new delivery man
      delivery_man = get_next_delivery_man_for hungry_man
      if delivery_man
        puts "Found another delivery man"
        send_on_delivery delivery_man, hungry_man
        package.retry = true
        package.save
      else
        puts "Couldn't find another delivery man"
        msg = "I regret to inform you that your burrito was lost in transit. "
        msg += "You can request another burrito using this command:\n"
        msg += "/cloudburrito feed me"
        Messenger.notify hungry_man, msg
      end
    else
      puts "Burrito #{package._id} in en route!"
    end
  end

  def self.feed(params)
    hungry_man_id = params["user_id"]
    hungry_man = Patron.where(:user_id => hungry_man_id)
    # Check if hungry man is allowed to feed based on these rules:
    # 1) Must be in the pool
    # 2) Must be active
    # 3) Can't be a delivery man
    # 4) Can't be waiting for a burrito
    unless hungry_man.exists?
      return "Please join CloudBurrito!"
    end
    hungry_man = hungry_man.first
    return "Please join the pool" unless hungry_man.is_active?
    return "*You* should be delivering a burrito!" if hungry_man.is_on_delivery?
    return "You already have a burrito coming!" if hungry_man.is_waiting?
    return "Stop being so greedy! Wait #{hungry_man.time_until_hungry}s." if hungry_man.is_greedy?
    
    # Check if we can find delivery man
    delivery_man = get_next_delivery_man_for hungry_man
    if delivery_man
      send_on_delivery delivery_man, hungry_man
      "Burrito incoming!"
    else
      "How about this? Get your own burrito."
    end
  end

  def self.en_route(params)
    patron_id = params["user_id"]
    # Check if the patron exists
    patron = Patron.where(:user_id => patron_id)
    return "You aren't a part of CloudBurrito..." unless patron.exists?
    # Check if the patron is on delivery
    patron = patron.first
    return "You aren't on a delivery..." unless patron.is_on_delivery?
    package = patron.active_delivery
    return "You've already acked this request..." if package.en_route
    # Ack the package
    puts "Package acked by delivery_man #{patron_id}."
    package.en_route = true
    package.save
    "Make haste!"
  end

  def self.received(params)
    patron_id = params["user_id"]
    # Check if the patron exists
    patron = Patron.where(:user_id => patron_id)
    return "You aren't a part of CloudBurrito..." unless patron.exists?
    # Check if the patron received any burritos
    patron = patron.first
    # Check if patron has an in coming burrito
    return "You don't have any in coming burritos" unless patron.is_waiting?
    # Mark the package as received 
    puts "Package received by hungry_man #{patron_id}."
    package = patron.incoming_burrito
    package.received = true
    package.en_route = true
    package.delivery_time = Time.now
    package.save
    # Notify delivery_man that he can order more burritos
    msg = "Your delivery has been acked. You can request more burritos!"
    Messenger.notify package.delivery_man, msg
    "Enjoy!"
  end

  def self.status(params)
    patron_id = params["user_id"]
    # Check if patron exists
    patron = Patron.where(:user_id => patron_id)
    return "You aren't part of CloudBurrito..." unless patron.exists?
    patron = patron.first
    return "You don't have any in coming burritos" unless patron.is_waiting?
    package = patron.incoming_burrito
    return "This burrito is on it's way!" if package.en_route
    "You burrito is still in the fridge"
  end

  def self.join(params)
    patron_id = params["user_id"]
    patron = Patron.where(:user_id => patron_id).first_or_create!
    patron.is_active = true
    patron.last_time_activated = Time.now
    patron.save
    "Please enjoy our fine selection of burritos!"
  end
end
