require_relative 'patron'
require_relative 'package'
require_relative 'settings'
require_relative 'messenger'

class Controller

  # Find the next available delivery man
  def get_next_delivery_man_for(hungry_man)
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
  def send_on_delivery(delivery_man, hungry_man)
    # Create the new package
    package = Package.new
    package.delivery_man = delivery_man
    package.hungry_man = hungry_man
    package.save
    # Notify delivery man of his duties
    msg = "Go get a burrito for <@#{hungry_man.user_id}>."
    Messenger.notify delivery_man, msg
    # Start a new thread to verify package delivery
    Thread.new { verify_en_route package }
  end

  # Verify that a burrito is headed to hungry man
  def verify_en_route(package)
    hungry_man = package.hungry_man
    delivery_man = package.delivery_man
    # Loop until the package is en route or stale
    while not (package.en_route or package.is_stale?) do
      sleep 1
    end
    if not package.en_route
      # Mark the delivery_man inactive
      delivery_man.is_active = false
      delivery_man.save
      msg = "You are too slow..."
      #Messenger.notify delivery_man, msg
      # Mark the package as failed
      package.failed = true
      package.save
      # Try to find a new delivery man
      delivery_man = get_next_delivery_man_for hungry_man
      if delivery_man
        package.retry = true
        package.save
        send_on_delivery delivery_man, hungry_man
      else
        msg = "I regret to inform you that your burrito was lost in transit."
        Messenger.notify hungry_man, msg
      end
    end
  end

  def self.feed(hungry_man_id)
    hungry_man = Patron.where(:user_id => hungry_man_id)
    # Check if hungry man is allowed to feed based on these rules:
    # 1) Must be in the pool
    # 2) Must be active
    # 3) Can't be a delivery man
    # 4) Can't be waiting for a burrito
    if not hungry_man.exists?
      return "Please join CloudBurrito!"
    end
    hungry_man = hungry_man.first
    if not hungry_man.is_active?
      return "Please join the pool!"
    elsif hungry_man.is_on_delivery?
      return "*You* should be delivering a burrito!"
    elsif hungry_man.is_already_waiting?
      return "You already have a burrito coming!"
    elsif hungry_man.is_greedy?
      return "Stop being so greedy! You need to wait #{hungry_man.time_until_hungry}s."
    end
    
    # Check if we can find delivery man
    delivery_man = get_next_delivery_man_for hungry_man
    if delivery_man
      send_on_delivery delivery_man, hungry_man
      "Burrito incoming!"
    else
      "How about this? Get your own burrito."
    end
  end

  def self.en_route(patron_id)
    # Check if the patron exists
    patron = Patron.where(:user_id => patron_id)
    return "You aren't a part of CloudBurrito..." unless patron.exists?
    # Check if the patron has packages
    patron = patron.first
    package = patron.deliveries.where(failed: false)
    return "You've never been asked to deliver..." unless package.exists?
    # Check if the patron should be delivering
    package = package.last
    return "You aren't delivering a burrito..." if package.received
    # Check if the package as already been acked
    return "You've already acked this request..." if package.en_route
    # Ack the package
    package.en_route = true
    package.save
    "Make haste!"
  end

  def self.received(patron_id)
    # Check if the patron exists
    patron = Patron.where(:user_id => patron_id)
    return "You aren't a part of CloudBurrito..." unless patron.exists?
    # Check if the patron received any burritos
    patron = patron.first
    package = patron.burritos.where(failed: false)
    return "You've never received a burrito from us..." unless package.exists?
    # Has already acked this burrito
    package = package.last
    return "You've already acked this burrito..." if package.received
    # Mark the package as received 
    package.received = true
    package.en_route = true
    package.delivery_time = Time.now
    package.save
    "Enjoy!"
  end

  def self.burrito_status(patron_id)
    # Check if patron exists
    patron.where(:user_id => patron_id)
    return "You aren't part of CloudBurrito..." unless patron.exists?
    patron = patron.first
    package = patron.burritos.where(failed: false)
    return "You haven't ordered any burritos..." unless package.exists?
    package = package.last
    return "Your last burrito was already delivered..." if package.recevied
    return "This burrito is on it's way!" if package.en_route
    "You burrito is still in the fridge"
  end

  def self.join(patron_id)
    patron = Patron.where(:user_id => patron_id)
    if patron.exists?
      patron = patron.first
      patron.is_active = true
      patron.last_time_activated = Time.now
      patron.save
      "Please enjoy our fine selection of burritos!"
    else
      Patron.new(:user_id => patron_id).save
      "Welcome new Cloud Burrito patron!"
    end
  end
end
