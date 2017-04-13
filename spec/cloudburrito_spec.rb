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
    Package.each.map(&:delete)
    Patron.each.map(&:delete)
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

  def zero_activated_time(x)
    p = Patron.find(x)
    p.last_time_activated = Time.at 0
    p.save
  end

  it "can load the home page" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Burritos are in the oven!')
  end

  it "needs a token to feed a patron" do
    post '/feedme', :user_id => '1'
    expect(last_response).not_to be_ok
  end

  it "needs a user_id to feed a patron" do
    post '/feedme', :token => token
    expect(last_response).not_to be_ok
  end

  it "can't feed a user that doesn't exist" do
    feed_patron '1'
    expect(last_response.body).to eq("Please join CloudBurrito!")
  end

  it "needs a token to add a patron" do
    post '/join', :user_id => '1'
    expect(last_response).not_to be_ok
  end

  it "needs a user_id to add a patron" do
    post '/join', :token => token
    expect(last_response).not_to be_ok
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

  it "can add a second patron" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    create_patron '2'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
  end

  it "can feed a patron when another is available" do
    create_patron '1'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    create_patron '2'
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
    zero_activated_time '1'
    feed_patron '1'
    expect(last_response.body).to eq("Burrito incoming!")
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
end
