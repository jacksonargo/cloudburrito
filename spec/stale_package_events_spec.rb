require_relative '../lib/events'
require 'rspec'
require 'rack/test'

describe "Event manager" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end
end
