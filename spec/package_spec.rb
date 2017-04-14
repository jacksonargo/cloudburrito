require_relative '../cloudburrito'
require 'rspec'
require 'rack/test'

describe "A burrito in transit" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    Package.delete_all
    Patron.delete_all
  end

  it "Can be created and modified" do
    b = Package.new
    p1 = Patron.new(user_id: '1')
    p2 = Patron.new(user_id: '2')
    b.hungry_man = p1
    b.delivery_man = p2
    expect(b.save).to eq(true)
    expect(b.is_stale?).to eq(false)
    b.force_stale = true
    expect(b.is_stale?).to eq(true)
  end

  it "Can't be saved unless it is owned" do
    expect(Package.new.save).to eq(false)
  end
end
