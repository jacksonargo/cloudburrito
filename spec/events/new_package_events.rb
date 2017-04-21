require_relative '../../events/new_package_events'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The NewPackageEvents class' do
  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Package.delete_all
    Message.delete_all
  end

  let(:events) { NewPackageEvents.new }

  context '#unassigned_packages' do
    let(:hman) { Patron.create user_id: '1' }
    it 'does not include failed packages' do
      10.times { Package.create hungry_man: hman, failed: true }
      expect(events.unassigned_packages.count).to be 0
    end
    it 'does not include received packages' do
      10.times { Package.create hungry_man: hman, received: true }
      expect(events.unassigned_packages.count).to be 0
    end
    it 'does not include stale packages' do
      10.times { Package.create hungry_man: hman, force_stale: true }
      expect(events.unassigned_packages.count).to be 0
    end
    it 'returns unassigned packages' do
      10.times { Package.create hungry_man: hman }
      expect(events.unassigned_packages.count).to be 10
    end
  end

  context '#get_delivery_man' do
    it 'is nil if none are eligible' do
      expect(events.get_delivery_man).to be nil
    end
    it 'returns new active dman' do
      dman = Patron.create user_id: '2', is_active: true
      expect(events.get_delivery_man).to eq dman
    end
  end

  context '#assign_next' do
    context 'when a new package is created,' do
      let(:hman) { Patron.create user_id: '1' }
      before(:each) { Package.create hungry_man: hman }

      context 'if there are no delivery men,' do
        before(:each) { events.assign_next }
        it 'marks package as failed.' do
          expect(Package.last.failed?).to be true
        end
        it 'no unassigned packages left.' do
          expect(events.unassigned_packages.count).to be 0
        end
        context 'creates message for hungry man' do
          let(:msg) { Message.last }
          it('and message exists.') { expect(msg).not_to be(nil) }
          it('and assigned to hungry man.') { expect(msg.to).to eq(hman) }
          it 'and says the burrito is dropped.' do
            expect(msg.text).to eq 'Your burrito was dropped! Please try again later.'
          end
        end
      end

      context 'there are delivery men,' do
        before(:each) do
          Patron.create user_id: '2', is_active: true
          events.assign_next
        end
        it 'marks the package assigned.' do
          expect(Package.last.assigned?).to be true
        end
        it 'no unassigned packages left.' do
          expect(events.unassigned_packages.count).to be 0
        end
        it 'assigns to delivery man.' do
          dman = Patron.last
          expect(Package.last.delivery_man).to eq dman
        end
        context 'creates message for delivery man' do
          let(:msg) { Message.last }
          it('and message exists.') { expect(msg).not_to be(nil) }
          it('and assigned to delivery man.') do
            dman = Patron.last
            expect(msg.to).to eq(dman)
          end
          it 'and says the you need to deliver.' do
            text = "You've been volunteered to get a burrito for #{hman}. "
            text += 'Please ACK this request by replying */cloudburrito serving*'
            expect(msg.text).to eq text
          end
        end
      end
    end

    context 'two new packages are created' do
      let(:patr1) { Patron.create user_id: '1' }
      let(:patr2) { Patron.create user_id: '2' }
      before(:each) do
        Package.create hungry_man: patr1
        Package.create hungry_man: patr2
      end
      context 'assigns packages first in first out' do
        before(:each) do
          Patron.create user_id: '3', is_active: true
          events.assign_next
        end
        it 'first package is assigned' do
          expect(Package.first.assigned?).to be true
        end
        it 'second package is unassigned' do
          expect(Package.last.assigned?).to be false
        end
        it 'one unassigned package' do
          expect(events.unassigned_packages.count).to be 1
        end
      end
    end
  end

  context '#stop' do
    it 'stops the thread' do
      events.start
      events.stop
      expect(events.thread.alive?).to be false
    end
  end

  context '#start' do
    let(:hman) { Patron.create user_id: '1' }

    before(:each) { events.start }
    after(:each) { events.stop }

    it 'creates a thread' do
      expect(events.thread.alive?).to be true
    end

    context 'when unassgined package exist,' do
      it 'assigns them' do
        # Create patrons to be assigned as delivery men
        (2..11).each { |x| Patron.create user_id: x.to_s, is_active: true }
        Package.create hungry_man: hman
        Package.create hungry_man: Patron.find('2')
        Package.create hungry_man: Patron.find('3')
        events.wait_for_complete
        expect(events.unassigned_packages.count).to eq 0
      end
    end

    context 'when stale packages exist,' do
      before(:each) do
        (2..11).each { |x| Patron.create user_id: x.to_s, is_active: true }
        Package.create hungry_man: hman, created_at: Time.at(0)
        Package.create hungry_man: Patron.find('2'), created_at: Time.at(0)
        Package.create hungry_man: Patron.find('3'), created_at: Time.at(0)
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
    it 'returns when no more unassigned packages' do
      events.start
      events.wait_for_complete
      expect(events.unassigned_packages.exists?).to eq false
      events.stop
    end
  end
end
