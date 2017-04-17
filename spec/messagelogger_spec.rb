require_relative '../cloudburrito'
require 'rspec'
require 'rack/test'

describe "Logging requests" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    MessageLogger.delete_all
    Patron.delete_all
  end

  it "Can be created" do
    MessageLogger.new
  end

  it "Cannot be saved unless connected to a Patron" do
    p = Patron.new user_id: '1'
    log = MessageLogger.new
    expect(log.save).to eq(false)
    log.patron = p
    expect(log.save).to eq(true)
  end

  it "Patron can reference it and it can reference patron" do
    p = Patron.new user_id: '1'
    log = MessageLogger.new patron: p
    log.save
    expect(p.message_loggers.first).to eq(log)
    expect(log.patron).to eq(p)
  end
end
