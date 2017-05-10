require_relative '../../events/new_package_events'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The NewPackageEvents class' do
  def app
    CloudBurrito
  end

  before(:each) do
    Pool.delete_all
    Patron.delete_all
    Package.delete_all
    Message.delete_all
  end

  let(:events) { NewPackageEvents.new }

  context '#unassigned_packages' do
    let(:hman) { create(:hman) }
    it 'does not include failed packages' do
      10.times { create(:failed_pack) }
      expect(events.unassigned_packages.count).to be 0
    end
    it 'does not include received packages' do
      10.times { create(:received_pack) }
      expect(events.unassigned_packages.count).to be 0
    end
    it 'returns unassigned packages' do
      10.times { create(:package) }
      expect(events.unassigned_packages.count).to be 10
    end
  end

  context '#get_delivery_man' do
    context 'no patrons in hungry_man pool' do
      after(:each) { expect(events.get_delivery_man).to be(nil) }
      context('no patrons at all') do
        it('returns nill') { }
      end

      context('some patrons in other pools') do
        it('returns nill') do
          pool = create(:pool)
          create(:active_patron, pool: pool)
        end
      end
    end

    context 'one patron in hungry_man pool' do
      let(:pool) { create(:pool) }
      let(:patron) { create(:patron, pool: pool) }
      context 'patron cant deliver' do
        before(:each) { patron.inactive! }
        it('returns nil') { expect(events.get_delivery_man).to be(nil) }
      end
      context 'patron can deliver' do
        before(:each) { patron.active! }
        it('returns patron') { expect(events.get_delivery_man).to eq(patron) }
      end
    end
  end

  context '#assign_next' do
    context 'when a new package is created,' do
      let(:hman) { create(:hman) }
      before(:each) { create(:package, hungry_man: hman) }

      context 'if the package is locked' do
        before(:each) do
          Locker.lock Package.first
          events.assign_next
        end
        it 'does not modify the package' do
          expect(events.unassigned_packages.count).to be 1
        end
      end

      context 'if there are no delivery men,' do
        before(:each) { events.assign_next }
        it 'the package is not locked' do
          expect(Locker.unlock(Package.last)).to be false
        end
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
          create(:active_patron)
          events.assign_next
        end
        it 'the package is not locked' do
          expect(Locker.unlock(Package.last)).to be false
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
            text = "You've been volunteered to get a burrito for #{hman.slack_link}. "
            text += 'Please ACK this request by replying */cloudburrito serving*'
            expect(msg.text).to eq text
          end
        end
      end
    end

    context 'two new packages are created' do
      let(:patr1) { create(:patron) }
      let(:patr2) { create(:patron) }
      before(:each) do
        create(:package, hungry_man: patr1)
        create(:package, hungry_man: patr2)
      end
      context 'assigns packages first in first out' do
        before(:each) do
          create(:active_patron)
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
    let(:hman) { create(:hman) }

    before(:each) { events.start }
    after(:each) { events.stop }

    it 'creates a thread' do
      expect(events.thread.alive?).to be true
    end

    context 'when unassgined package exist,' do
      it 'assigns them' do
        # Create patrons to be assigned as delivery men
        10.times { create(:active_patron) }
        # Create some packages
        3.times { create(:package) }
        events.wait_for_complete
        expect(events.unassigned_packages.count).to eq 0
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
