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

  let(:hman) { Patron.create user_id: '1' }
  let(:dman) { Patron.create user_id: '2' }
  let(:package) { Package.create hungry_man: hman, delivery_man: dman }

  context '#delivered!' do
    before(:each) { package.delivered! }
    it 'sets a delivery_time' do
      expect(package.delivery_time).not_to be nil
    end
    it 'sets received' do
      expect(package.received).to be true
    end
    it 'sets en_route' do
      expect(package.en_route).to be true
    end
  end

  context '#delivered?' do
    it 'not when created' do
      expect(package.delivered?).to be false
    end
    it 'when delivered' do
      package.delivered!
      expect(package.delivered?).to be true
    end
  end

  context '#is_stale?' do
    it 'is not stale when created' do
      expect(package.is_stale?).to eq(false)
    end

    it 'can be manually set to stale' do
      package.force_stale = true
      package.save
      expect(package.is_stale?).to eq(true)
    end

    it 'becomes stale after 300 seconds' do
      package.created_at = Time.now - 300
      expect(package.is_stale?).to eq(true)
    end
  end

  it "Can be created and modified" do
    b = Package.new
    p1 = Patron.new(user_id: '1')
    p2 = Patron.new(user_id: '2')
    b.hungry_man = p1
    b.delivery_man = p2
    expect(b.save).to eq(true)
  end

  it "Can't be saved unless it is owned" do
    expect(Package.new.save).to eq(false)
  end
end
