require_relative 'cloudburrito'

# Create the events
events = {
  :new_package_events => NewPackageEvents.new,
  :stale_package_events => StalePackageEvents.new,
  :unsent_message_events => UnsentMessageEvents.new
}

# Start the events
events.each_key{ |key| events[key].start }

# Start the server
run CloudBurrito
