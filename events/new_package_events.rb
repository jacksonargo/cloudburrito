require_relative '../models/patron'
require_relative '../models/package'
require_relative '../models/message'
require_relative '../lib/events'

class NewPackageEvents < Events
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

  def next_action
    assign_next
    sleep 0.1
  end
end
