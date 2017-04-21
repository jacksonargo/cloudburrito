# frozen_string_literal: true

require_relative '../models/patron'
require_relative '../models/package'
require_relative '../models/message'
require_relative '../lib/events'

class StalePackageEvents < Events
  def wait_for_complete
    while stale_packages.count > 0
    end
  end

  def stale_packages
    Package.each.select(&:stale?)
  end

  def replace_next
    stale_package = stale_packages.first
    return if stale_package.nil?
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

  def next_action
    replace_next
    sleep 0.1
  end
end
