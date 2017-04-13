require_relative "../lib/patron.rb"
require 'rspec'
require 'rack/test'

describe "A cloud burrito patron" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  it 'can be deleted' do
    Patron.each.map(&:delete)
    expect(Patron.count).to eq(0)
  end

  it 'can be created' do
    x = Patron.new(user_id: Time.now)
    expect(x.save).to eq(true)
  end

  it 'is not on delivery' do
    x = Patron.last
    expect(x.is_on_delivery?).to eq(false)
  end

  it 'is not waiting' do
    x = Patron.last
    expect(x.is_already_waiting?).to eq(false)
  end

  it 'is greedy' do
    x = Patron.last
    expect(x.is_greedy?).to eq(true)
  end

  it 'is not sleeping' do
    x = Patron.last
    expect(x.is_sleeping?).to eq(false)
  end
end
