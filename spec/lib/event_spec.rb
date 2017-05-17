# frozen_string_literal: true

require_relative '../../lib/event'
require 'rspec'

RSpec.describe 'Event' do
  let(:dummy_class) { Class.new{ include Event } }
  let(:events) { dummy_class.new }
end
