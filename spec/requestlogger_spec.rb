require_relative '../cloudburrito'
require 'rspec'
require 'rack/test'

describe "Logging requests" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
  end

  it "Can be created and modified" do
    RequestLogger.new
  end
end
