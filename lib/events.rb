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
