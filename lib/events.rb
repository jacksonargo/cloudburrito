# frozen_string_literal: true

# Events
# A meta-class that defines basic ops for my event classes.
class Events
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
