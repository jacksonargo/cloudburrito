# frozen_string_literal: true

require_relative '../../../lib/event'
require 'rspec'

RSpec.describe 'Event::Base' do
  let(:events) { Event::Base.new }

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
