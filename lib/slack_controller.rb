require_relative 'patron'
require_relative 'package'
require_relative 'messenger'

class SlackController
  attr_reader :patron, :params, :actions

  def initialize(params)
    # Save the params
    @params = params
    # Add the user to the database if they don't already exist
    @patron = Patron.where(user_id: params["user_id"]).first_or_create!
    @patron.save
    # Actions list
    @actions = ["feed", "serving", "full", "status", "join", "stats", "leave"]
  end

  def feed
    puts "Trying to feed #{@patron}..."
    puts "Checking if he's allowed to get a burrito..."
    hungry_man = @patron
    # Check if hungry man is allowed to feed based on these rules:
    # 1) Must be active in the pool
    # 2) Can't be a delivery man
    # 3) Can't be waiting for a burrito
    # 4) Must wait between orders (determined by greediness)
    return "Please join the pool." unless hungry_man.is_active?
    return "*You* should be delivering a burrito!" if hungry_man.on_delivery?
    return "You already have a burrito coming!" if hungry_man.waiting?
    return "Stop being so greedy! Wait #{hungry_man.time_until_hungry}s." if hungry_man.greedy?
    
    # Check if we can find delivery man
    puts "#{hungry_man} passed checks."
    puts "Finding a delivery man for #{hungry_man}..."
    delivery_man = get_next_delivery_man_for hungry_man
    if delivery_man
      puts "Found delivery man #{delivery_man}."
      send_on_delivery delivery_man, hungry_man
      "Burrito incoming!\nPlease use */cloudburrito full* to acknowledge that you have received your burrito."
    else
      puts "No available deliver man for #{hungry_man}"
      "How about this? Get your own burrito."
    end
  end

  def serving
    # Check if the patron is on delivery
    return "You aren't on a delivery..." unless @patron.on_delivery?
    package = @patron.active_delivery
    return "You've already acked this request..." if package.en_route
    # Ack the package
    puts "Package acked by delivery_man #{@patron._id}."
    package.en_route = true
    package.save
    "Make haste!"
  end

  def full
    # Check if patron has an in coming burrito
    return "You don't have any in coming burritos" unless @patron.waiting?
    # Mark the package as received 
    puts "Package received by hungry_man #{@patron._id}."
    delivery_man = @patron.incoming_burrito.delivery_man
    @patron.incoming_burrito.delivered!
    # Notify delivery_man that he can order more burritos
    msg = "Your delivery has been acked. You can request more burritos!"
    Messenger.notify delivery_man, msg
    "Enjoy!"
  end

  def status
    return "You don't have any in coming burritos" unless @patron.waiting?
    package = @patron.incoming_burrito
    return "This burrito is on it's way!" if package.en_route
    "You burrito is still in the fridge"
  end

  def join
    if @patron.active?
        "You are already part of the pool party!\nRequest a burrito with */cloudburrito feed*."
    else
        @patron.active!
        "Please enjoy our fine selection of burritos!"
    end
  end

  def leave
    @patron.is_active = false
    @patron.save
   "You have left the burrito pool party."
  end

  def stats
    "Use this url to see your stats.\n#{@patron.stats_url}"
  end

  private

  # Find the next available delivery man
  def get_next_delivery_man_for(hungry_man)
    # Get all the active patrons
    candidates = Patron.where(is_active: true)
    # Check that there are active patrons
    return nil unless candidates.exists?
    # Select delivery man based on these rules:
    # 1) Must be active (per above)
    # 2) Must not be on a delivery
    # 3) Cannot be selected more than once per sleep time
    # 4) You cannot deliver to yourself
    candidates = candidates.each.select do |p|
      not (p.on_delivery? or p.sleepy? or p == hungry_man)
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
    msg = "You've been volunteered to get a burrito for #{hungry_man}. "
    msg += "Please ACK this request by replying */cloudburrito serving*"
    Messenger.notify delivery_man, msg
    # Start a new thread to verify package delivery
    Thread.new { verify_en_route package }
  end

  # Verify that a burrito is headed to hungry man
  def verify_en_route(package)
    hungry_man = package.hungry_man
    delivery_man = package.delivery_man
    # Loop until the package is en route or stale
    puts "Waiting for ack from #{delivery_man} for delivery #{package}"
    until (package.en_route or package.is_stale? or package.failed) do
      package.reload
    end
    unless package.en_route
      # Mark the delivery_man inactive
      puts "Delivery man took to long; finding another."
      delivery_man.is_active = false
      delivery_man.save
      msg = "You've been bounced out of the pool. Use this command "
      msg += "to rejoin the pool and start downloading burritos:\n"
      msg += "*/cloudburrito join*"
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
        msg += "*/cloudburrito feed*"
        Messenger.notify hungry_man, msg
      end
    else
      puts "Burrito #{package._id} in en route!"
    end
  end
end
