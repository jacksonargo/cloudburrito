# frozen_string_literal: true

require_relative '../models/patron'
require_relative '../models/package'
require_relative '../models/message'
require_relative '../models/locker'
require_relative '../lib/event'

# StalePackageEvents
# A class to process packages once they become lost.
module Event
  class Event::LostPackage < Event::Base
    def wait_for_complete
      while lost_packages.count > 0
      end
    end

    def lost_packages
      Package.each.select(&:lost?)
    end

    def fail_next
      # Get the next package
      lost_package = lost_packages.first
      # Do nothing if it's nil
      return if lost_package.nil?
      # Do nothing if we can't lock it
      return unless Locker.lock lost_package
      # Log that we are replacing it
      logger.info "Package #{lost_package._id} is lost."
      dman = lost_package.delivery_man
      hman = lost_package.hungry_man
      # Fail the package
      lost_package.failed!
      # Send a message to hungry man
      text = "It doesn't look like you received your burrito. "
      text += "Since it has been an hour, you can order another burrito. "
      text += "When you receive the burrito, be sure to tell Cloudburrito "
      text += "with _/cloudburrito full_ or you wont get points."
      Message.create to: hman, text: text
      # Send a message to delivery man
      text = "It appears <@#{hman.slack_user_id}> never received the burrito. "
      text += "Since it has been an hour, you can order burritos again, "
      text += "but you don't get points for the last delivery."
      Message.create to: dman, text: text
      # Unlock the lost package
      Locker.unlock lost_package
    end

    def next_action
      while lost_packages.count > 0 do
        fail_next
      end
      sleep 0.1
    end
  end
end
