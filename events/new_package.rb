# frozen_string_literal: true

require_relative '../models/patron'
require_relative '../models/package'
require_relative '../models/message'
require_relative '../models/locker'
require_relative '../lib/event'

# NewPackageEvents
# A class to assign new packages once they are created.
module Event
  class Event::NewPackage < Event::Base
    def wait_for_complete
      while unassigned_packages.count > 0
      end
    end

    def unassigned_packages
      Package.where(assigned: false, failed: false, received: false)
    end

    def get_delivery_man(pool)
      Patron.where(pool: pool).each.select(&:can_deliver?).sample
    end

    def assign_next
      # Only do something is an unassigned package exists
      return unless unassigned_packages.exists?
      # Work on the first package
      package = unassigned_packages.first
      # Lock it
      return unless Locker.lock package
      hman = package.hungry_man
      logger.info "New package #{package} for #{hman}."
      # Try to get a delivery man
      dman = get_delivery_man hman.pool
      if dman
        logger.info "Assigned #{dman} to deliver #{package}."
        package.assign! dman
        # Tell dman he's assigned
        text = "You've been volunteered to get a burrito for #{hman.slack_link}. "
        text += 'Please ACK this request by replying */cloudburrito serving*'
        Message.create to: dman, text: text
      else
        logger.info "No one is available to deliver #{package}."
        package.failed!
        # Tell hungry man if one isn't available
        text = 'Your burrito was dropped! Please try again later.'
        Message.create to: hman, text: text
      end
      # Unlock the package
      Locker.unlock package
    end

    def next_action
      while unassigned_packages.exists? do
        assign_next
      end
      sleep 0.1
    end
  end
end
