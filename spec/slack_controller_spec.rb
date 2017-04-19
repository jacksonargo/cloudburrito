require_relative '../cloudburrito'
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

  let (:patron) { Patron.create user_id: "1" }
  let (:params) { { "user_id" => patron.user_id } }
  let (:controller) { SlackController.new params }

  context '#initialize' do
    it 'set params' do
      expect(controller.params).to eq(params)
    end
    it 'set patron' do
      expect(controller.patron).to eq(patron)
    end
    it 'allows required actions' do
      expect(controller.actions).to eq(["feed", "serving", "full", "status", "join", "stats", "leave"])
    end
  end

  context '#feed' do
    let(:other) { Patron.create user_id: "2" }
    it 'patron must be active' do
      controller.patron.is_active = false
      expect(controller.feed).to eq("Please join the pool.")
    end
    it 'patron cant be on delivery' do
      patron.active!
      Package.create hungry_man: other, delivery_man: patron
      expect(controller.feed).to eq("*You* should be delivering a burrito!")
    end
    it 'patron cant be waiting' do
      patron.active!
      Package.create hungry_man: patron, delivery_man: other
      expect(controller.feed).to eq("You already have a burrito coming!")
    end
    it 'patron cant be greedy' do
      patron.active!
      expect(patron.is_greedy?).to be true
      expect(controller.feed).to eq("Stop being so greedy! Wait #{patron.time_until_hungry}s.")
    end
  end

  context '#stats' do
    it 'returns url to check stats' do
      expect(controller.stats).not_to be_empty
    end
    it 'returns unique url' do
      expect(controller.stats).not_to eq(controller.stats)
    end
  end

  context '#join' do
    it 'checks if patron is active' do
      controller.patron.active!
      expect(controller.join).to eq("You are already part of the pool party!\nRequest a burrito with */cloudburrito feed*.")
    end
    it 'activated inactive patron' do
      expect(controller.join).to eq("Please enjoy our fine selection of burritos!")
      expect(controller.patron.active?).to be true
    end
  end

  context '#leave' do
    it 'marks a patron as inactive' do
      expect(controller.leave).to eq("You have left the burrito pool party.")
      expect(controller.patron.active?).to eq(false)
    end
  end

  context '#serving' do
    let (:other)  { Patron.create user_id: "2" }
    it 'checks if patron has incoming burritos' do
      expect(controller.serving).to eq("You aren't on a delivery...")
    end
    it 'check if a package has already been acked' do
      Package.create en_route: true, hungry_man: other, delivery_man: patron
      expect(controller.serving).to eq("You've already acked this request...")
    end
    it 'marks package as received' do
      p = Package.create hungry_man: other, delivery_man: patron
      expect(controller.serving).to eq("Make haste!")
      p.reload
      expect(p.en_route).to be true
    end
  end

  context '#full' do
  end

  def create_burrito_and_patrons
    # There shoudn't be any patrons or burritos
    expect(Patron.count).to eq(0)
    expect(Package.count).to eq(0)
    # Create two patrons
    c = SlackController.new "user_id" => '1'
    c.join
    c = SlackController.new "user_id" => '2'
    c.join
    expect(Patron.count).to eq(2)
    p1 = Patron.find('1')
    p2 = Patron.find('2')
    # Make p1 not greedy
    p1.force_not_greedy = true
    p1.save
    expect(p1.is_greedy?).to eq(false)
    # Create a burrito for p1
    c = SlackController.new "user_id" => '1'
    c.feed
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
    (1..10).each do |x| 
      c = SlackController.new("user_id" => x.to_s)
      c.join
    end
    expect(Patron.count).to eq(10)
    Patron.each do |p| 
      expect(p.is_active).to eq(true)
      expect(p.is_greedy?).to eq(true)
    end
  end

  it "Won't create a second patron with same id" do
    (1..10).each do 
      c = SlackController.new("user_id" => '1')
      c.join
    end
    expect(Patron.count).to eq(1)
  end

  it "can create burritos" do
    create_burrito_and_patrons
  end

  it "can check the status of burritos" do
    p1, _p2, _b = create_burrito_and_patrons
    c = SlackController.new "user_id" => p1.user_id
    c.status
  end

  it "Hungryman can ack and Delivery can ack" do
    p1, p2, b = create_burrito_and_patrons
    # p2 should ack that he's on delivery
    c = SlackController.new "user_id" => '2'
    c.serving
    p1.reload
    p2.reload
    b.reload
    expect(b.en_route).to eq(true)
    expect(b.received).to eq(false)
    expect(p1.is_waiting?).to eq(true)
    expect(p2.is_on_delivery?).to eq(true)
    # p1 should ack that he received the burrito
    c = SlackController.new "user_id" => '1'
    c.full
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
    c = SlackController.new "user_id" => '3'
    c.join
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
