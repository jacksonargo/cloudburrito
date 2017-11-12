# frozen_string_literal: true

require_relative '../lib/event.rb'
require_relative '../events/new_package'
require_relative '../events/stale_package'
require_relative '../events/unsent_message'

Event::NewPackage.new.start
Event::StalePackage.new.start
Event::UnsentMessage.new.start
