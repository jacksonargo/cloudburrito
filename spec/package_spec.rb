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

  context '#latency_time' do
    it 'returns time between created and delivery' do
      package.created_at = Time.now - 30
      package.delivery_time = package.created_at + 30
      expect(package.latency_time).to eq(30)
    end
  end

  context '#failed!' do
    before(:each) { package.failed! }
    it 'sets failed' do
      expect(package.failed).to be true
    end
  end

  context '#failed?' do
    it 'not when created' do
      expect(package.failed?).to be false
    end
    it 'when failed' do
      package.failed!
      expect(package.failed?).to be true
    end
  end

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
    it 'not when created' do
      expect(package.is_stale?).to eq(false)
    end

    it 'when forced' do
      package.force_stale = true
      package.save
      expect(package.is_stale?).to eq(true)
    end

    it 'after 300 seconds' do
      package.created_at = Time.now - 300
      expect(package.is_stale?).to eq(true)
    end
  end

  context '#new' do
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

    it "can be saved if only owned by hungry_man" do
      p = Package.create hungry_man: hman
      expect(p.save).to eq(true)
    end

    it "can be created with hungry_man and delivery_man" do
      p = Package.create hungry_man: hman, delivery_man: dman
      expect(p.hungry_man).to eq(hman)
      expect(p.delivery_man).to eq(dman)
    end
  end

  context '#assigned?' do
    it 'not when created' do
      expect(package.assigned?).to be false
    end
    it 'when assigned' do
      package.assign! dman
      expect(package.assigned?).to be true
    end
  end

  context '#assign!' do
    before(:each) { package.assign! dman }
    it 'sets delivery_man to arg' do
      expect(package.delivery_man).to eq(dman)
    end
    it 'can be saved' do
      expect(package.save).to be true
    end
  end
end
