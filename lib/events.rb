require_relative 'patron'
require_relative 'package'
require_relative 'message'

class Events
  attr_reader :thread

  def start
    @thread = Thread.new do
      loop do 
        replace_stale_packages
        assign_next
      end
    end
  end

  def stop
    @thread.kill
    while @thread.alive?
    end
  end

  def wait_for_complete
    while unassigned_packages.count > 0
    end
  end

  def unassigned_packages
    Package.where(assigned: false, failed: false, received: false)
  end

  def get_delivery_man
    Patron.each.select{ |p| p.can_deliver? }.sample
  end

  def assign_next
    # Only do something is an unassigned package exists
    return unless unassigned_packages.exists?
    # Work on the first package
    package = unassigned_packages.first
    hman = package.hungry_man
    # Try to get a delivery man
    dman = get_delivery_man
    if dman
      package.assign! dman
      # Tell dman he's assigned
      text = "You've been volunteered to get a burrito for #{hman}. "
      text += "Please ACK this request by replying */cloudburrito serving*"
      Message.create to: dman, text: text
    else
      package.failed!
      # Tell hungry man if one isn't available
      text = "Your burrito was dropped! Please try again later."
      Message.create to: hman, text: text
    end
  end

  def notify(patron, msg)
  end

  def get_stale_packages
    Package.each.select{ |p| p.stale? }
  end

  def replace(stale_package)
    dman = stale_package.delivery_man
    hman = stale_package.hungry_man
    # Make dman inactive
    dman.inactive!
    Message.create to: dman, text: "You've been kicked from the pool!"
    # Fail the package
    stale_package.failed!
    # Create a new package for hungry man
    Package.create hungry_man: hman
  end

  def replace_stale_packages
    get_stale_packages.each do |stale_package|
      replace stale_package
    end
  end
end
