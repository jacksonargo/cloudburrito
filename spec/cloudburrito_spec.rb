require_relative '../cloudburrito.rb'
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

  File.delete('../data/patrons.json') if File.exists?('../data/patrons.json')
  token = Settings.verification_token

  it "can load the home page" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Burritos are in the oven!')
  end

  it "needs a token to list patrons" do
    get '/list_patrons'
    expect(last_response).not_to be_ok
  end

  it "can list patrons with a token" do
    get '/list_patrons', :token => token
    expect(last_response).to be_ok
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
    post '/join', { :token => token, :user_id => '1' }
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
  end

  it "wont try to add the same patron twice" do
    post '/join', { :token => token, :user_id => '1' }
    expect(last_response).to be_ok
    expect(last_response.body).to eq("You are already a patron of Cloud Burrito!")
  end

  it "needs a token to feed a patron" do
    post '/feedme', :user_id => '1'
    expect(last_response).not_to be_ok
  end

  it "needs a user_id to feed a patron" do
    post '/feedme', :token => token
    expect(last_response).not_to be_ok
  end

  it "can't feed a patron if there's only one" do
    post '/feedme', { :token => token, :user_id => '1' }
    expect(last_response).to be_ok
    expect(last_response.body).to eq("How about this? Get your own burrito.")
  end

  it "can add a second patron" do
    post '/join', { :token => token, :user_id => '2' }
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Welcome new Cloud Burrito patron!')
  end
end
