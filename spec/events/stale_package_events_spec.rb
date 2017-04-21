require_relative '../../events/stale_package_events'
require 'rspec'

ENV['RACK_ENV'] = 'test'
Mongoid.load!("config/mongoid.yml")

describe "The StalePackageEvent class" do

  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Package.delete_all
    Message.delete_all
  end

  let(:events) { StalePackageEvents.new }

  context '#stale_packages' do
    let(:hman) { Patron.create user_id: '1' }
    let(:dman) { Patron.create user_id: '2' }
    it 'returns [] when there are no packages' do
      expect(events.stale_packages).to eq []
    end
    it 'returns [] when there are no assigned packages' do
      Package.create hungry_man: hman
      expect(events.stale_packages).to eq []
    end
    it 'returns [] when no stale packages' do
      p = Package.create hungry_man: hman
      p.assign! dman
      expect(events.stale_packages).to eq []
    end
    it 'returns stale packages' do
      p = Package.create hungry_man: hman
      p.assign! dman
      p.stale!
      expect(events.stale_packages.first).to eq p
    end
  end

  context '#replace_next' do

    context 'no packages exist' do
      before(:each) { events.replace_next }
      it 'doesnt fail' do
      end
    end

    context 'one package becomes stale' do
      let(:hman) { Patron.create user_id: '1' }
      let(:dman) { Patron.create user_id: '2', is_active: true }
      before(:each) do
        Package.create(
          hungry_man: hman, 
          delivery_man: dman, 
          force_stale: true, 
          assigned: true
        )
        events.replace_next
      end

      it 'the first package is no longer stale' do
        expect(Package.first.stale?).to be false
      end

      it 'there are no stale packages' do
        expect(events.stale_packages).to eq []
      end

      it 'marks the package as failed' do
        expect(Package.first.failed?).to be true
      end

      it 'creates a new package' do
        expect(Package.count).to be 2
      end

      it 'the new package is not stale' do
        expect(Package.last.stale?).to be false
      end

      it 'new package is assigned to hungry man' do
        expect(Package.last.hungry_man).to eq hman
      end

      it 'makes delivery man inactive' do
        dman.reload
        expect(dman.inactive?).to be true
      end

      context 'creates a message for delivery man' do
        it('exists') { expect(Message.count).to be(1) }
        it 'assigned to delivery man' do
          expect(Message.last.to).to eq dman
        end
        it 'says you been booted' do
          text = "You've been kicked from the pool!"
          expect(Message.last.text).to eq text
        end
      end
    end

    context 'two packages become stale' do
      let(:patr1) { Patron.create user_id: '1' }
      let(:patr2) { Patron.create user_id: '2' }
      before(:each) do
        Package.create hungry_man: patr1, force_stale: true, assigned: true
        Package.create hungry_man: patr2, force_stale: true, assigned: true
        events.replace_next
      end
 
      context 'processes them first in fist out' do
        it 'first package should be failed' do
          expect(Package.first.failed).to be true
        end
        it 'last package should have same hungry man' do
          p1 = Package.first
          p3 = Package.last
          expect(p1.hungry_man).to eq(p3.hungry_man)
        end
        it 'next stale package is different from first package' do
          expect(events.stale_packages.first).not_to eq(Package.first)
        end
      end
    end
  end

  context '#start' do
    let(:hman) { Patron.create user_id: '1' }

    before(:each) { events.start }
    after(:each) { events.stop }

    it 'creates a thread' do
      expect(events.thread.alive?).to be true
    end

    context 'when stale packages exist,' do
      before(:each) do
        (2..11).each {|x| Patron.create user_id: x.to_s, is_active: true }
        Package.create hungry_man: hman, assigned: true, force_stale: true
        Package.create hungry_man: hman, assigned: true, force_stale: true
        Package.create hungry_man: hman, assigned: true, force_stale: true
      end
      it 'marks them failed' do
        events.wait_for_complete
        expect(Package.where(failed: true).count).to be 3
      end
      it 'creates replacement packages' do
        events.wait_for_complete
        expect(Package.where(failed: false).count).to be 3
      end
    end
  end

  context '#wait_for_complete' do
    it 'returns when no more stale packages' do
      events.start
      events.wait_for_complete
      expect(events.stale_packages).to eq []
      events.stop
    end
  end
end
