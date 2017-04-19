require_relative "../cloudburrito"
require 'rspec'
require 'rack/test'

describe "A cloud burrito patron" do
  include Rack::Test::Methods

  def app
    CloudBurrito
  end

  let(:patron) { Patron.create user_id: '1' }

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

  it 'is not sleeping when created' do
    expect(patron.time_until_awake).to eq(0)
    expect(patron.is_sleeping?).to eq(false)
  end

  context '#active!' do
    before(:each) { patron.active! }
    it 'sets last time activated' do
      expect(patron.last_time_activated.to_i).to eq(Time.now.to_i)
    end
    it 'sets is_active' do
      expect(patron.is_active).to be true
    end
  end

  context '#active?' do
    it 'not when created' do
      expect(patron.active?).to be false
    end
    it 'when activated' do
      patron.active!
      expect(patron.active?).to be true
    end
  end

  context "#is_sleeping?" do
    let(:other) { Patron.create user_id: '2' }
    let(:package) { Package.create hungry_man: other, delivery_man: patron }
    it 'not when created' do
      expect(patron.is_sleeping?).to eq(false)
    end

    it 'after delivery' do
      package.delivered!
      expect(patron.is_sleeping?).to eq(true)
    end

    it 'not 3600s after delivery' do
      package.delivered!
      package.delivery_time = Time.now - 3600
      package.save
      expect(patron.is_sleeping?).to eq(false)
    end
  end

  context "#is_greedy?" do
    let(:other) { Patron.create user_id: '2' }
    let(:package) { Package.create hungry_man: patron, delivery_man: other }

    it 'when created' do
      expect(patron.is_greedy?).to eq(true)
    end

    it 'when last time activated is now' do
      patron.last_time_activated = Time.now
      expect(patron.is_greedy?).to eq(true)
    end

    it 'after receiving burrito' do
      package.delivered!
      expect(patron.is_greedy?).to eq(true)
    end

    it 'not when forced not greedy' do
      patron.force_not_greedy = true
      expect(patron.is_greedy?).to eq(false)
    end

    it 'not when last act time is 0' do
      patron.last_time_activated = Time.at 0
      expect(patron.is_greedy?).to eq(false)
    end

    it 'not after 3600 seconds' do
      patron.last_time_activated = Time.now - 3600
      expect(patron.is_greedy?).to eq(false)
    end

    it 'not after 3600 seconds after receiving burrito' do
      patron.last_time_activated = Time.now - 3600
      package.delivered!
      package.delivery_time = Time.now - 3600
      package.save
      expect(patron.is_greedy?).to eq(false)
    end
  end


  context "#user_token" do
    it 'exists' do
      expect(patron.user_token).not_to be_empty
    end

    it 'is unique' do
      y = Patron.create(user_id: '2')
      expect(patron.user_token).not_to eq(y.user_token)
    end
  end
end
