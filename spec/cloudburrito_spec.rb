require_relative '../lib/cloudburrito.rb'
require 'rspec'
require 'rack/test'

describe 'The CloudBurrito settings' do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  it 'has a verification token' do
    expect(Settings.verification_token).not_to be_empty
  end
  
  it 'has an authentication token' do
    expect(Settings.auth_token).not_to be_empty
  end
end

describe 'The CloudBurrito app' do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    Package.where({}).delete
    Patron.where({}).delete
  end

  token = Settings.verification_token

  def create_patron(x)
    token = Settings.verification_token
    post '/join', { :token => token, :user_id => x }
    expect(last_response).to be_ok
  end

  def feed_patron(x)
    token = Settings.verification_token
    post '/feedme', { :token => token, :user_id => x }
    expect(last_response).to be_ok
  end

  def en_route_for(x)
    token = Settings.verification_token
    post '/en_route', { :token => token, :user_id => x }
    expect(last_response).to be_ok
  end

  def received_for(x)
    token = Settings.verification_token
    post '/received', { :token => token, :user_id => x }
    expect(last_response).to be_ok
  end

  def zero_activated_time(x)
    p = Patron.find(x)
    p.last_time_activated = Time.at 0
    p.save
  end

  def create_burrito(x, y)
    b = Package.new(delivery_man: Patron.find(x), hungry_man: Patron.find(y))
    b.save
    return b
  end

  it "can load the home page" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Burritos are in the oven!')
  end

  it "can send a burrito" do
    # Create patrons
    create_patron '1'
    create_patron '2'
    zero_activated_time '1'
    # Feed the first
    feed_patron '1'
    expect(last_response.body).to eq("Burrito incoming!")
    # Verify the package data
    hm = Patron.find('1')
    dm = Patron.find('2')
    expect(hm.burritos.exists?).to eq(true)
    expect(dm.deliveries.exists?).to eq(true)
    expect(hm.burritos.last).to eq(dm.deliveries.last)
    b = hm.burritos.last
    expect(b.en_route).to eq(false)
    expect(b.received).to eq(false)
    # Send an ack from dm
    sleep 2
    en_route_for dm.user_id
    expect(last_response.body).to eq("Make haste!")
    # Verify package data
    b.reload
    expect(b.en_route).to eq(true)
    expect(b.received).to eq(false)
    # Send receipt from hm
    received_for hm.user_id
    expect(last_response.body).to eq("Enjoy!")
    # Verify package data
    b.reload
    expect(b.en_route).to eq(true)
    expect(b.received).to eq(true)
    # Verify hm data
    hm.reload
    #hm.burritos.each.map(&:reload)
    expect(hm.is_greedy?).to eq(true)
    expect(hm.time_of_last_burrito).not_to eq(0)
    # Verify dm data
    dm.reload
    expect(dm.is_sleeping?).to eq(true)
    expect(dm.time_of_last_burrito).not_to eq(0)
  end

  it "can send a burrito when delivery man timesout" do
    # Create some patrons
    create_patron '1'
    create_patron '2'
    zero_activated_time '1'
    # Feed the first
    feed_patron '1'
    expect(last_response.body).to eq("Burrito incoming!")
    # Verify the package data
    hm = Patron.find('1')
    dm = Patron.find('2')
    expect(hm.burritos.exists?).to eq(true)
    expect(dm.deliveries.exists?).to eq(true)
    expect(hm.burritos.last).to eq(dm.deliveries.last)
    b = hm.burritos.last
    expect(b.en_route).to eq(false)
    expect(b.received).to eq(false)
    # Create a new patron to take over the package
    create_patron '3'
    # Mark the package as stale
    b.force_stale = true
    b.save
    expect(b.is_stale?).to eq(true)
    # Wait a second so the package will be failed
    sleep 3
    # Verify dm data
    dm.reload
    expect(dm.is_active).to eq(false)
    # Verify the package data
    b.reload
    expect(b.failed).to eq(true)
    expect(b.en_route).to eq(false)
    expect(b.received).to eq(false)
    # A new package should be created, so lets check for it
    hm.reload
    n = hm.burritos.last
    puts Package.count
    puts Patron.count
    expect(n).not_to eq(b)
  end

  it "needs a token to feed a patron" do
    post '/feedme', :user_id => '1'
    expect(last_response).not_to be_ok
  end

  it "needs a user_id to feed a patron" do
    post '/feedme', :token => token
    expect(last_response).not_to be_ok
  end

  it "needs a token to add a patron" do
    post '/join', :user_id => '1'
    expect(last_response).not_to be_ok
  end

  it "needs a user_id to add a patron" do
    post '/join', :token => token
    expect(last_response).not_to be_ok
  end

  it "needs a token to mark a delivery en route" do
    post '/en_route', :user_id => '1'
    expect(last_response).not_to be_ok
  end

  it "needs a user_id to mark a delivery en route" do
    post '/en_route', :token => token
    expect(last_response).not_to be_ok
  end

  it "needs a token to mark a burrito as received" do
    post '/received', :user_id => '1'
    expect(last_response).not_to be_ok
  end

  it "needs a user_id to mark a burrito as received" do
    post '/received', :token => token
    expect(last_response).not_to be_ok
  end

  it "can't feed a user that doesn't exist" do
    feed_patron '1'
    expect(last_response.body).to eq("Please join CloudBurrito!")
  end

  it "can't mark a burrito en route for a dne patron" do
    en_route_for '1'
    expect(last_response.body).to eq("You aren't a part of CloudBurrito...")
  end

  it "can't mark a dne burrito en route" do
    create_patron '1'
    en_route_for '1'
    expect(last_response.body).to eq("You've never been asked to deliver...")
  end

  it "won't mark a received burrito as en route" do
    create_patron '1'
    create_patron '2'
    b = create_burrito '1', '2'
    b.received = true
    b.save
    en_route_for '1'
    expect(last_response.body).to eq("You aren't delivering a burrito...")
  end

  it "won't mark an en route burrito as en route" do
    create_patron '1'
    create_patron '2'
    b = create_burrito '1', '2'
    b.en_route = true
    b.save
    en_route_for '1'
    expect(last_response.body).to eq("You've already acked this request...")
  end

  it "will mark an unacked burrito en route" do
    create_patron '1'
    create_patron '2'
    b = create_burrito '1', '2'
    en_route_for '1'
    expect(last_response.body).to eq("Make haste!")
    expect(b.en_route).to eq(true)
    expect(b.received).to eq(false)
  end

  it "can't mark a burrito received for a dne patron" do
    received_for '1'
    expect(last_response.body).to eq("You aren't a part of CloudBurrito...")
  end

  it "can't mark a dne burrito received" do
    create_patron '1'
    received_for '1'
    expect(last_response.body).to eq("You've never received a burrito from us...")
  end

  it "won't mark a received burrito received" do
    create_patron '1'
    create_patron '2'
    b = create_burrito '1', '2'
    b.received = true
    b.save
    received_for '2'
    expect(last_response.body).to eq("You've already acked this burrito...")
  end

  it "will mark an unrevied burrito as received" do
    create_patron '1'
    create_patron '2'
    b = create_burrito '1', '2'
    received_for '2'
    expect(last_response.body).to eq("Enjoy!")
    expect(b.received).to eq(true)
    expect(b.en_route).to eq(true)
  end

  it "can add a patron w/ user_id and token" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
  end

  it "wont try to add the same patron twice" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    create_patron '1'
    expect(last_response.body).to eq("Please enjoy our fine selection of burritos!")
  end

  it "will activate an inactive user" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    zero_activated_time '1'
    create_patron '1'
    expect(last_response.body).to eq("Please enjoy our fine selection of burritos!")
  end

  it "can't immediately feed a new patron" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    feed_patron '1'
    expect(last_response.body).to match(/Stop being so greedy! You need to wait \d+s./)
  end

  it "can't feed a patron if there aren't any available delivery men" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    zero_activated_time '1'
    feed_patron '1'
    expect(last_response.body).to eq("How about this? Get your own burrito.")
  end

  it "can add 10 second patrons" do
    (0..10).each do |x|
      create_patron x.to_s
      expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    end
  end

  it "wont let a hungry man request a second burrito" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    create_patron '2'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    zero_activated_time '1'
    zero_activated_time '2'
    feed_patron '1'
    expect(last_response.body).to eq("Burrito incoming!")
    feed_patron '1'
    expect(last_response.body).to eq("You already have a burrito coming!")
  end

  it "wont let a delivery man request a burrito" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    create_patron '2'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    zero_activated_time '1'
    zero_activated_time '2'
    feed_patron '1'
    expect(last_response.body).to eq("Burrito incoming!")
    feed_patron '2'
    expect(last_response.body).to eq("*You* should be delivering a burrito!")
  end

  it "will create a burrito for and wait for delivery_man ack" do
    create_patron '1'
    create_patron '2'
    zero_activated_time '1'
    zero_activated_time '2'
    feed_patron '1'
  end
end
