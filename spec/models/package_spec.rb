require_relative '../../models/package'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Package class' do
  def app
    CloudBurrito
  end

  before(:each) do
    Pool.delete_all
    Package.delete_all
    Patron.delete_all
  end

  let(:hman) { create(:hman) }
  let(:dman) { create(:dman) }
  let(:package) { create(:package, hungry_man: hman, delivery_man: dman) }

  context '#create' do
    context 'received is true' do
      let(:package) { create(:received_pack) }
      it('received_at is not nil') { expect(package.received_at).not_to be(nil) }
    end

    context 'en route is true' do
      let(:package) { create(:en_route_pack) }
      it('en_route_at is not nil') { expect(package.en_route_at).not_to be(nil) }
    end

    context 'assigned is true' do
      let(:package) { create(:assigned_pack) }
      it('assigned_at is not nil') { expect(package.assigned_at).not_to be(nil) }
    end

    context 'failed is true' do
      let(:package) { create(:failed_pack) }
      it('failed_at is not nil') { expect(package.failed_at).not_to be(nil) }
    end
  end

  context '#latency' do
    before(:each) { package.created_at = Time.now - 30 }
    after(:each) { expect(package.latency).to eq(30) }

    it 'package is received' do
      package.received!
      package.received_at = package.created_at + 30
    end
    it 'package is failed' do
      package.failed!
      package.failed_at = package.created_at + 30
    end
  end

  context '#failed!' do
    before(:each) { package.failed! }
    it 'sets failed' do
      expect(package.failed).to be true
    end
  end

  context '#failed?' do
    it 'not when first created' do
      expect(package.failed?).to be false
    end
    it 'when failed' do
      package.failed!
      expect(package.failed?).to be true
    end
  end

  context '#received!' do
    before(:each) { package.received! }
    it 'sets received at' do
      expect(package.received_at).not_to be nil
    end
    it 'sets received' do
      expect(package.received).to be true
    end
    it 'sets en_route' do
      expect(package.en_route?).to be true
    end
  end

  context '#received?' do
    it 'not when first created' do
      expect(package.received?).to be false
    end
    it 'when received' do
      package.received!
      expect(package.received?).to be true
    end
  end

  context '#en_route!' do
    before(:each) { package.en_route! }
    it 'sets en_route' do
      expect(package.en_route).to be true
    end
    it 'sets en_route_at' do
      expect(package.en_route).to be true
    end
  end

  context '#en_route?' do
    it 'not when first created' do
      expect(package.en_route?).to be false
    end
    it 'when en_route' do
      package.en_route!
      expect(package.en_route?).to be true
    end
  end

  context '#stale?' do
    it 'not when first created' do
      expect(package.stale?).to eq(false)
    end

    it 'not when first assigned' do
      package.assign! dman
      expect(package.stale?).to eq(false)
    end

    it '300 seconds after assigned' do
      package.assign! dman
      package.assigned_at = Time.now - 300
      expect(package.stale?).to eq(true)
    end

    context 'when forced' do
      before(:each) do
        package.assign! dman
        package.stale!
      end
      context 'is stale when' do
        it 'new package and assigned' do
          expect(package.stale?).to eq(true)
        end
      end

      context 'is not stale when' do
        after(:each) { expect(package.stale?).to be false }
        it('en route')   { package.en_route = true }
        it('failed')     { package.failed! }
        it('received')   { package.received! }
        it('unassigned') { package.assigned = false }
      end
    end
  end

  context '#stale!' do
    before(:each) { package.stale! }
    it 'sets force_stale' do
      expect(package.force_stale).to be true
    end
  end

  context '#new' do
    it 'Can be created and modified' do
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

    it 'can be saved if only owned by hungry_man' do
      p = Package.create hungry_man: hman
      expect(p.save).to eq(true)
    end

    it 'can be created with hungry_man and delivery_man' do
      p = Package.create hungry_man: hman, delivery_man: dman
      expect(p.hungry_man).to eq(hman)
      expect(p.delivery_man).to eq(dman)
    end

    it 'sets received_at if created w/ recevied: true' do
      p = Package.create hungry_man: hman, delivery_man: dman, received: true
      expect(p.received_at).not_to be nil
    end
    it 'sets en_route_at if created w/ recevied: true' do
      p = Package.create hungry_man: hman, delivery_man: dman, en_route: true
      expect(p.en_route_at).not_to be nil
    end
    it 'sets assigned_at if created w/ recevied: true' do
      p = Package.create hungry_man: hman, delivery_man: dman, assigned: true
      expect(p.assigned_at).not_to be nil
    end
    it 'sets failed_at if created w/ recevied: true' do
      p = Package.create hungry_man: hman, delivery_man: dman, failed: true
      expect(p.failed_at).not_to be nil
    end
  end

  context '#assigned?' do
    it 'not when first created' do
      expect(package.assigned?).to be false
    end
    it 'when assigned' do
      package.assign! dman
      expect(package.assigned?).to be true
    end
  end

  context '#assign!' do
    before(:each) do
      package.assign! dman
    end
    it 'sets delivery_man to arg' do
      expect(package.delivery_man).to eq(dman)
    end
    it 'updates the assigned_at time' do
      expect(package.assigned_at).not_to be_nil
    end
    it 'sets assigned' do
      expect(package.assigned).to be true
    end
    it 'can be saved' do
      expect(package.save).to be true
    end
  end
end
