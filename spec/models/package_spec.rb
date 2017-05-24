require_relative '../../models/package'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Package class' do
  before(:each) do
    Pool.delete_all
    Package.delete_all
    Patron.delete_all
  end

  let(:hman) { create(:hman) }
  let(:dman) { create(:dman) }
  let(:package) { create(:package, hungry_man: hman, delivery_man: dman) }

  context '#valid?' do
    context 'returns false when' do
      let(:package) { create(:package) }
      after(:each) { expect(package.valid?).to be(false) }

      context 'failed is true and' do
        before(:each) { package.failed = true }
        it('received is true') { package.received = true }
      end

      context 'received is true and' do
        before(:each) { package.received = true }
        it('failed is true') { package.failed = true }
      end
    end
  end

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

  context '#lost?' do
    context 'unassigned package' do
      let(:package) { create(:package) }

      context 'failed' do
        before(:each) { package.failed = true }

        context 'not received' do
          before(:each) { package.received = false }
          it('is not lost') { expect(package.lost?).to be(false) }
        end

        context 'received' do
          before(:each) { package.received = true }
          it('is not lost') { expect(package.lost?).to be(false) }
        end
      end

      context 'not failed' do
        before(:each) { package.failed = false }

        context 'not received' do
          before(:each) { package.received = false }
          it('is not lost') { expect(package.lost?).to be(false) }
        end

        context 'received' do
          before(:each) { package.received = true }
          it('is not lost') { expect(package.lost?).to be(false) }
        end
      end
    end

    context 'assigned package' do
      let(:package) { create(:assigned_pack) }

      context 'less than 1 hour since assigned' do
        before(:each) { package.assigned_at = Time.now }

        context 'not failed' do
          before(:each) { package.failed = false }

          context 'not received' do
            before(:each) { package.received = false }
            it('is not lost') { expect(package.lost?).to be(false) }
          end

          context 'received' do
            before(:each) { package.received = true }
            it('is not lost') { expect(package.lost?).to be(false) }
          end
        end

        context 'failed' do
          before(:each) { package.failed = true }

          context 'not received' do
            before(:each) { package.received = false }
            it('is not lost') { expect(package.lost?).to be(false) }
          end

          context 'received' do
            before(:each) { package.received = true }
            it('is not lost') { expect(package.lost?).to be(false) }
          end
        end
      end

      context 'greater than 1 hour since assigned' do
        before(:each) { package.assigned_at -= 3600 }

        context 'not failed' do
          before(:each) { package.failed = false }

          context 'not received' do
            before(:each) { package.received = false }
            it('is lost') { expect(package.lost?).to be(true) }
          end

          context 'received' do
            before(:each) { package.received = true }
            it('is not lost') { expect(package.lost?).to be(false) }
          end
        end

        context 'failed' do
          before(:each) { package.failed = true }

          context 'not received' do
            before(:each) { package.received = false }
            it('is not lost') { expect(package.lost?).to be(false) }
          end

          context 'received' do
            before(:each) { package.received = true }
            it('is not lost') { expect(package.lost?).to be(false) }
          end
        end
      end
    end
  end

  context '#new' do
    it 'Can be created and modified' do
      expect(create(:package).save).to eq(true)
    end

    it "Can't be saved unless it is owned" do
      expect(Package.new.save).to eq(false)
    end

    it 'can be saved if only owned by hungry_man' do
      expect(create(:package, delivery_man: nil).save).to eq(true)
    end

    it 'can be created with hungry_man and delivery_man' do
      hman = create(:hman)
      dman = create(:dman)
      p = create(:package)
      expect(p.hungry_man).to eq(hman)
      expect(p.delivery_man).to eq(dman)
    end

    it 'sets received_at if created w/ received: true' do
      expect(create(:received_pack).received_at).not_to be nil
    end
    it 'sets en_route_at if created w/ en_route: true' do
      expect(create(:en_route_pack).en_route_at).not_to be nil
    end
    it 'sets assigned_at if created w/ assigned: true' do
      expect(create(:assigned_pack).assigned_at).not_to be nil
    end
    it 'sets failed_at if created w/ failed: true' do
      expect(create(:failed_pack).failed_at).not_to be nil
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
