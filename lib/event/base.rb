# frozen_string_literal: true

require_relative '../cloudburrito_logger'
# A class that defines basic ops for my event classes.
module Event
  class Event::Base
    include CloudBurritoLogger
    attr_reader :thread
    def start
      @thread = Thread.new do
        loop { next_action }
      end
    end

    def stop
      @thread.kill
      while @thread.alive?
      end
    end
  end
end
