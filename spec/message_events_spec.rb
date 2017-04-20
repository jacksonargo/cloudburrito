require_relative '../lib/message_events.rb'
require 'rspec'
require 'rack/test'

describe 'The MessageEvents class' do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    Message.delete_all
  end

  context '#send_next' do
  end

  context '#unsent' do
  end

  context 'messages exist' do
    it 'knows messages exist' do
    end

    it 'sends existing messages' do
    end
  end
end
