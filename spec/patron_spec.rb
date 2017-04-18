require_relative "../cloudburrito"
require 'rspec'
require 'rack/test'

describe "A cloud burrito patron" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  before(:each) do
    Package.each.map(&:delete)
    Patron.each.map(&:delete)
  end

  it 'can be deleted' do
    Patron.each.map(&:delete)
    expect(Patron.count).to eq(0)
  end

  it 'can be created with string id' do
    x = Patron.new(user_id: '1')
    expect(x.save).to eq(true)
  end

  it 'last activated time is now' do
    x = Patron.new(user_id: '1')
    x.last_time_activated = Time.now
  end

  it 'is not on delivery when created' do
    x = Patron.new(user_id: '1')
    expect(x.is_on_delivery?).to eq(false)
  end

  it 'is not waiting when created' do
    x = Patron.new(user_id: '1')
    expect(x.is_waiting?).to eq(false)
  end

  it 'is greedy when created' do
    x = Patron.new(user_id: '1')
    expect(x.time_until_hungry).not_to eq(0)
    expect(x.is_greedy?).to eq(true)
  end

  it 'is not sleeping when created' do
    x = Patron.new(user_id: '1')
    expect(x.time_until_awake).to eq(0)
    expect(x.is_sleeping?).to eq(false)
  end

  it 'is not greedy when last act time is 0' do
    x = Patron.new(user_id: '1')
    x.last_time_activated = Time.at 0
    expect(x.time_until_hungry).to eq(0)
    expect(x.is_greedy?).to eq(false)
  end

  it 'is created with a user token' do
    x = Patron.create(user_id: '1')
    expect(x.user_token).not_to be_empty
  end

  it 'two users have different tokens when created' do
    x = Patron.create(user_id: '1')
    y = Patron.create(user_id: '2')
    expect(x.user_token).not_to eq(y.user_token)
  end
end
