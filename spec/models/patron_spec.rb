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

    it 'inactive when created' do
      x = Patron.new(user_id: '1')
      expect(x.active?).to be false
    end

    it 'active_at is nil' do
      x = Patron.new(user_id: '1')
      expect(x.active_at).to be nil
    end

    it 'sets active_at if created with active true' do
      x = Patron.create user_id: '1', active: true
      expect(x.active_at).not_to be nil
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
    let(:dman) { Patron.create user_id: '2' }
    it 'returns 0 if no burritos received' do
      expect(patron.time_of_last_burrito).to eq(Time.at(0))
    end
    it 'returns now if burrito just delivered' do
      p = Package.create hungry_man: patron, delivery_man: dman, received: true
      expect(patron.time_of_last_burrito.to_i).to eq p.received_at.to_i
    end
  end

  context '#time_of_last_delivery' do
    let(:hman) { Patron.create user_id: '2' }
    it 'returns 0 if no deliveries completed' do
      expect(patron.time_of_last_delivery).to eq(Time.at(0))
    end
    it 'returns now if burrito just delivered' do
      p = Package.create hungry_man: hman, delivery_man: patron, received: true
      expect(patron.time_of_last_delivery.to_i).to eq p.received_at.to_i
    end
  end

  context '#time_until_hungry' do
  end

  context '#time_until_awake' do
  end

  context '#active!' do
    before(:each) { patron.active! }
    it 'sets active_at' do
      expect(patron.active_at).not_to be nil
    end
    it 'sets active' do
      expect(patron.active).to be true
    end
  end

  context '#active?' do
    it 'not when created' do
      expect(patron.active?).to be false
    end
    it 'when active' do
      patron.active!
      expect(patron.active?).to be true
    end
  end

  context '#inactive!' do
    before(:each) { patron.inactive! }
    it 'unsets active' do
      expect(patron.active).to eq(false)
    end
    it 'sets inactive_at' do
      expect(patron.inactive_at).not_to be nil
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
      package.received!
      expect(patron.sleepy?).to eq(true)
    end

    it 'not 3600s after delivery' do
      package.received!
      package.received_at = Time.now - 3600
      package.save
      expect(patron.sleepy?).to eq(false)
    end
  end

  context '#greedy?' do
    let(:other) { Patron.create user_id: '2' }
    let(:package) { Package.create hungry_man: patron, delivery_man: other }

    it 'when first created' do
      expect(patron.greedy?).to eq(true)
    end

    it 'when first active' do
      patron.active!
      expect(patron.greedy?).to eq(true)
    end

    it 'when inactive' do
      patron.inactive!
      expect(patron.greedy?).to be true
    end

    it 'not when forced not greedy' do
      patron.force_not_greedy = true
      expect(patron.greedy?).to eq(false)
    end

    it 'not after being active for 3600 seconds' do
      patron.active!
      patron.active_at = Time.now - 3600
      expect(patron.greedy?).to eq(false)
    end

    context 'active and after 3600 seconds' do
      before(:each) do
        patron.active!
        patron.active_at = Time.now - 3600
      end

      it 'greedy when marked inactive' do
        patron.inactive!
        expect(patron.greedy?).to eq(true)
      end

      it 'greedy just after receiving burrito' do
        package.received!
        expect(patron.greedy?).to eq(true)
      end

      it 'not greedy 3600s after receiving burrito' do
        patron.active_at = Time.now - 3600
        package.received!
        package.received_at = Time.now - 3600
        package.save
        expect(patron.greedy?).to eq(false)
      end
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

  context '#slack_link' do
    it 'returns a link to the slack user' do
      expect(patron.slack_link).to eq "<@#{patron.user_id}>"
    end
  end

  context '#slack_user_info' do
    it 'returns {} if user_id is invalid' do
      expect(patron.slack_user_info).to eq Hash.new
    end
  end

  context '#slack_first_name' do
    it 'returns the name of the user in slack' do
      user_id = ENV['SLACK_TEST_USER_ID'].dup
      name = ENV['SLACK_TEST_USER_NAME']
      expect(user_id).to eq 'U1G86TJ72'
      tester = Patron.create user_id: user_id
      expect(tester.slack_first_name).to eq name
    end
    it 'returns user_id if user_id is invalid' do
      expect(patron.slack_first_name).to eq '1'
    end
  end
end
