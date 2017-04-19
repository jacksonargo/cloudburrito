require_relative 'patron'
require_relative 'package'

class Events
  def start
    Thread.new do
      loop { assign_next }
    end
  end

  def wait_for_complete
    while unassigned_packages.count > 0
    end
  end

  def unassigned_packages
    Package.where(assigned: false)
  end

  def get_delivery_man
    Patron.each.select{ |p| p.can_deliver? }.sample
  end

  def assign_next
    return unless unassigned_packages.exists?
    package = unassigned_packages.first
    hman = package.hungry_man
    dman = get_delivery_man
    unless dman
      package.failed!
      notify(hman, "Your burrito was dropped! Please try again later.")
    end
    package.assign! dman
  end

  def notify(patron, msg)
  end
end
