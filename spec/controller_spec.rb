require_relative '../lib/cloudburrito.rb'
require 'rspec'
require 'rack/test'

describe 'The CloudBurrito controller' do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Package.delete_all
  end

  def create_burrito_and_patrons
    # There shoudn't be any patrons or burritos
    expect(Patron.count).to eq(0)
    expect(Package.count).to eq(0)
    # Create two patrons
    Controller.join '1'
    Controller.join '2'
    expect(Patron.count).to eq(2)
    p1 = Patron.find('1')
    p2 = Patron.find('2')
    # Make p1 not greedy
    p1.force_not_greedy = true
    p1.save
    expect(p1.is_greedy?).to eq(false)
    # Create a burrito for p1
    Controller.feed '1'
    p1.reload
    p2.reload
    expect(Package.count).to eq(1)
    b = Package.first
    expect(p1.is_waiting?).to eq(true)
    expect(p1.incoming_burrito).to eq(b)
    expect(p2.is_on_delivery?).to eq(true)
    expect(p2.active_delivery).to eq(b)
    expect(b.en_route).to eq(false)
    expect(b.received).to eq(false)
    return p1, p2, b
  end

  it "Can create patrons" do
    (1..10).each{|x| Controller.join x.to_s}
    expect(Patron.count).to eq(10)
    Patron.each do |p| 
      expect(p.is_active).to eq(true)
      expect(p.is_greedy?).to eq(true)
    end
  end

  it "Won't create a second patron with same id" do
    (1..10).each{|x| Controller.join '1'}
    expect(Patron.count).to eq(1)
  end

  it "can create burritos" do
    create_burrito_and_patrons
  end

  it "Hungryman can ack and Delivery can ack" do
    p1, p2, b = create_burrito_and_patrons
    # p2 should ack that he's on delivery
    Controller.en_route '2'
    p1.reload
    p2.reload
    b.reload
    expect(b.en_route).to eq(true)
    expect(b.received).to eq(false)
    expect(p1.is_waiting?).to eq(true)
    expect(p2.is_on_delivery?).to eq(true)
    # p1 should ack that he received the burrito
    Controller.received '1'
    p1.reload
    p2.reload
    b.reload
    expect(b.en_route).to eq(true)
    expect(b.received).to eq(true)
    expect(p1.is_waiting?).to eq(false)
    expect(p2.is_on_delivery?).to eq(false)
    p1.force_not_greedy = false
    p1.save
    expect(p1.is_greedy?).to eq(true)
    expect(p2.is_sleeping?).to eq(true)
  end

  it "will look for a new delivery man if package goes stale" do
    p1, p2, b = create_burrito_and_patrons
    # Create a new patron to deliver
    Controller.join '3'
    p3 = Patron.find '3'
    # p2 doesn't ack
    b.force_stale = true
    b.save
    # Monitoring determines package is stale
    x = Time.now
    while(not b.failed or (Time.now - x).to_f > 1) do
      b.reload
    end
    p2.reload
    expect(b.failed).to eq(true)
    expect(p2.is_active).to eq(false)
    # A new package is created
    x = Time.now
    while(not b.retry or (Time.now - x).to_f > 1) do
      b.reload
    end
    expect(b.retry).to eq(true)
    expect(Package.count).to eq(2)
    b = Package.last
    expect(b.en_route).to eq(false)
    expect(b.received).to eq(false)
    expect(p1.is_waiting?).to eq(true)
    expect(p3.is_on_delivery?).to eq(true)
  end
end
