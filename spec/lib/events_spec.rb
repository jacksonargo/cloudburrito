require_relative '../../lib/events'
require 'rspec'

describe "The Events Class" do

  def app
    CloudBurrito
  end

  let(:events) { Events.new }

  context '#stop' do
    it 'stops the thread' do
      events.start
      events.stop
      expect(events.thread.alive?).to be false
    end
  end

  context '#start' do

    before(:each) { events.start }
    after(:each) { events.stop }

    it 'creates a thread' do
      expect(events.thread.alive?).to be true
    end
  end
end
