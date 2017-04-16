require_relative '../cloudburrito'
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
    Package.delete_all
    Patron.delete_all
  end

  token = Settings.verification_token

  def create_patron(x)
    token = Settings.verification_token
    post '/slack', { token: token, user_id: x, text: "join" }
    expect(last_response).to be_ok
  end

  def feed_patron(x)
    token = Settings.verification_token
    post '/slack', { token: token, user_id: x, text: "feed" }
    expect(last_response).to be_ok
  end

  def en_route_for(x)
    token = Settings.verification_token
    post '/slack', { token: token, user_id: x, text: "en_route" }
    expect(last_response).to be_ok
  end

  def received_for(x)
    token = Settings.verification_token
    post '/slack', { token: token, user_id: x, text: "received" }
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

  it "can load the plain home page" do
    header "Accept", "text/plain"
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq("Welcome to Cloud Burrito!")
  end

  it "the html home page is different" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).not_to eq("Welcome to Cloud Burrito!")
  end

  it "can load the 404 page" do
    header "Accept", "text/plain"
    get '/notapage'
    expect(last_response).not_to be_ok
    expect(last_response.body).to eq("404: Burrito Not Found!")
  end

  it "will only repond to /slack if token is correct" do
    post '/slack'
    expect(last_response).not_to be_ok
  end

  it "will load the help page" do
    token = Settings.verification_token
    post '/slack', { token: token, user_id: '1' }
    expect(last_response).to be_ok
  end

  it "will mark an unacked burrito en route" do
    create_patron '1'
    create_patron '2'
    b = create_burrito '1', '2'
    en_route_for '1'
    expect(last_response.body).to eq("Make haste!")
    b.reload
    expect(b.en_route).to eq(true)
    expect(b.received).to eq(false)
  end

  it "will mark an unrevied burrito as received" do
    create_patron '1'
    create_patron '2'
    b = create_burrito '1', '2'
    received_for '2'
    expect(last_response.body).to eq("Enjoy!")
    b.reload
    expect(b.received).to eq(true)
    expect(b.en_route).to eq(true)
  end

  it "can add a patron w/ user_id and token" do
    create_patron '1'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
  end

  it "wont try to add the same patron twice" do
    create_patron '1'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    create_patron '1'
    expect(last_response.body).to eq("Please enjoy our fine selection of burritos!")
  end

  it "will activate an inactive user" do
    create_patron '1'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    zero_activated_time '1'
    create_patron '1'
    expect(last_response.body).to eq("Please enjoy our fine selection of burritos!")
  end

  it "can't immediately feed a new patron" do
    create_patron '1'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    feed_patron '1'
    expect(last_response.body).to match(/Stop being so greedy! Wait \d+s./)
  end

  it "can't feed a patron if there aren't any available delivery men" do
    create_patron '1'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    zero_activated_time '1'
    feed_patron '1'
    expect(last_response.body).to eq("How about this? Get your own burrito.")
  end

  it "can add 10 second patrons" do
    (0..10).each do |x|
      create_patron x.to_s
      expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    end
  end

  it "wont let a hungry man request a second burrito" do
    create_patron '1'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    create_patron '2'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    zero_activated_time '1'
    zero_activated_time '2'
    feed_patron '1'
    expect(last_response.body).to eq("Burrito incoming!")
    feed_patron '1'
    expect(last_response.body).to eq("You already have a burrito coming!")
  end

  it "wont let a delivery man request a burrito" do
    create_patron '1'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
    create_patron '2'
    expect(last_response.body).to eq('Please enjoy our fine selection of burritos!')
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