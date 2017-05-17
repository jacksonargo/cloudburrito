# frozen_string_literal: true
require_relative 'cloudburrito'

# Create the event threads
Event::NewPackage.new.start
Event::StalePackage.new.start
Event::UnsentMessage.new.start

# Start the server
run CloudBurrito
