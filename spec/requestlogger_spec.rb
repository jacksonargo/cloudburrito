require_relative '../cloudburrito'
require 'rspec'
require 'rack/test'

describe "Logging requests" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    RequestLogger.delete_all
  end

  it "Can be created" do
    RequestLogger.new
  end

  it "Cannot be saved unless connected to a Patron" do
    Patron.delete_all
    p = Patron.new user_id: '1'
    log = RequestLogger.new
    expect(log.save).to eq(false)
    log.patron = p
    expect(log.save).to eq(true)
  end

  it "Can reference it's patron and patron can reference it" do
    Patron.delete_all
    p = Patron.new user_id: '1'
    log = RequestLogger.new patron: p
    expect(p.request_loggers.first).to eq(log)
    expect(log.patron).to eq(p)
  end
end
