require_relative '../../models/patron'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Patron class' do
  def app
    CloudBurrito
  end

  let(:patron) { Patron.create user_id: '1' }

  before(:each) do
    Package.each.map(&:delete)
    Patron.each.map(&:delete)
  end

  context '#new' do
    it 'can be created with string id' do
      x = Patron.new(user_id: '1')
      expect(x.save).to eq(true)
    end
  end

  context '#active_delivery' do
    let(:hman) { Patron.create user_id: '2' }
    it 'nil when created' do
      expect(patron.active_delivery).to be nil
    end
    it 'nil when all packages delivered' do
      Package.create hungry_man: hman, delivery_man: patron, received: true
      expect(patron.active_delivery).to be nil
    end
    it 'is undelivered package' do
      b = Package.create hungry_man: hman, delivery_man: patron
      expect(patron.active_delivery).to eq(b)
    end
  end

  context '#on_delivery?' do
    let(:hman) { Patron.create user_id: '2' }
    it 'not when created' do
      expect(patron.on_delivery?).to be false
    end
    it 'when undelivered packages exist' do
      Package.create hungry_man: hman, delivery_man: patron
      expect(patron.on_delivery?).to be true
    end
    it 'not when all deliveries received' do
      Package.create hungry_man: hman, delivery_man: patron, received: true
      expect(patron.on_delivery?).to be false
    end
  end

  context '#incoming_burrito' do
    let(:dman) { Patron.create user_id: '2' }
    it 'nil when created' do
      expect(patron.incoming_burrito).to be nil
    end
    it 'nil when all burritos received' do
      Package.create hungry_man: patron, delivery_man: dman, received: true
      expect(patron.incoming_burrito).to be nil
    end
    it 'is unreceived burrito' do
      b = Package.create hungry_man: patron, delivery_man: dman
      expect(patron.incoming_burrito).to eq(b)
    end
  end

  context '#waiting?' do
    let(:dman) { Patron.create user_id: '2' }
    it 'not when created' do
      expect(patron.waiting?).to be false
    end
    it 'when undelivered packages exist' do
      Package.create hungry_man: patron, delivery_man: dman
      expect(patron.waiting?).to be true
    end
    it 'not when all deliveries received' do
      Package.create hungry_man: patron, delivery_man: dman, received: true
      expect(patron.waiting?).to be false
    end
  end

  context '#time_of_last_burrito' do
  end

  context '#time_of_last_delivery' do
  end

  context '#time_until_hungry' do
  end

  context '#time_until_awake' do
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

  context '#inactive!' do
    before(:each) { patron.inactive! }
    it 'unsets is_active' do
      expect(patron.is_active).to eq(false)
    end
  end

  context '#inactive?' do
    it 'when created' do
      expect(patron.inactive?).to be true
    end
    it 'not when activated' do
      patron.active!
      expect(patron.inactive?).to be false
    end
    it 'when deactivated' do
      patron.inactive!
      expect(patron.inactive?).to be true
    end
  end

  context '#sleepy?' do
    let(:other) { Patron.create user_id: '2' }
    let(:package) { Package.create hungry_man: other, delivery_man: patron }
    it 'not when created' do
      expect(patron.sleepy?).to eq(false)
    end

    it 'after delivery' do
      package.delivered!
      expect(patron.sleepy?).to eq(true)
    end

    it 'not 3600s after delivery' do
      package.delivered!
      package.delivery_time = Time.now - 3600
      package.save
      expect(patron.sleepy?).to eq(false)
    end
  end

  context '#greedy?' do
    let(:other) { Patron.create user_id: '2' }
    let(:package) { Package.create hungry_man: patron, delivery_man: other }

    it 'when created' do
      expect(patron.greedy?).to eq(true)
    end

    it 'when last time activated is now' do
      patron.last_time_activated = Time.now
      expect(patron.greedy?).to eq(true)
    end

    it 'after receiving burrito' do
      package.delivered!
      expect(patron.greedy?).to eq(true)
    end

    it 'not when forced not greedy' do
      patron.force_not_greedy = true
      expect(patron.greedy?).to eq(false)
    end

    it 'not when last act time is 0' do
      patron.last_time_activated = Time.at 0
      expect(patron.greedy?).to eq(false)
    end

    it 'not after 3600 seconds' do
      patron.last_time_activated = Time.now - 3600
      expect(patron.greedy?).to eq(false)
    end

    it 'not after 3600 seconds after receiving burrito' do
      patron.last_time_activated = Time.now - 3600
      package.delivered!
      package.delivery_time = Time.now - 3600
      package.save
      expect(patron.greedy?).to eq(false)
    end
  end

  context '#user_token' do
    it 'exists' do
      expect(patron.user_token).not_to be_empty
    end

    it 'is unique' do
      y = Patron.create(user_id: '2')
      expect(patron.user_token).not_to eq(y.user_token)
    end
  end

  context '#can_deliver?' do
    let(:hman) { Patron.create user_id: '2' }
    it 'when active' do
      patron.active!
      expect(patron.can_deliver?).to be true
    end
    it 'not when created' do
      expect(patron.can_deliver?).to be false
    end
    it 'not if inactive' do
      patron.inactive!
      expect(patron.can_deliver?).to be false
    end
    it 'not if on delivery' do
      Package.create hungry_man: hman, delivery_man: patron
      expect(patron.can_deliver?).to be false
    end
    it 'not if sleeping after delivery' do
      Package.create hungry_man: hman, delivery_man: patron, received: true
      expect(patron.can_deliver?).to be false
    end
  end
end
