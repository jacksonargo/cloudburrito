require_relative '../../events/stale_package_events'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The StalePackageEvent class' do
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
    context 'no packages' do
      it('returns []') { expect(events.stale_packages).to eq([]) }
    end

    context 'packages exist' do
      before(:each) { create(:package) }

      context 'no assigned packages' do
        it('returns []') { expect(events.stale_packages).to eq([]) }
      end

      context 'assigned packages exist' do
        before(:each) { create(:assigned_pack) }
        context 'no stale packages' do
          it('returns []') { expect(events.stale_packages).to eq([]) }
        end

        context 'stale package exist' do
          before(:each) { create(:stale_pack) }
          it('doesnt return []') { expect(events.stale_packages).not_to eq([]) }
          it('returns stale packages') do
            expect(events.stale_packages).to eq([Package.last])
          end
        end
      end
    end
  end

  context '#replace_next' do
    context 'no packages exist' do
      before(:each) { events.replace_next }
      it 'doesnt fail' do
      end
    end

    context 'one package becomes stale' do
      let(:hman) { create(:hman) }
      let(:dman) { create(:dman) }
      before(:each) { create(:stale_pack, hungry_man: hman, delivery_man: dman) }

      context 'the package is locked' do
        before(:each) do
          Locker.lock Package.first
          events.replace_next
        end
        it 'is not modified' do
          expect(events.stale_packages.count).to be 1
        end
      end

      context 'the package is not locked' do 
        before(:each) { events.replace_next }
        it 'the first package is no longer stale' do
          expect(Package.first.stale?).to be false
        end

        it 'the package is not locked' do
          expect(Locker.unlock(Package.first)).to be false
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
    end

    context 'two packages become stale' do
      let(:patr1) { create(:patron) }
      let(:patr2) { create(:patron) }
      before(:each) do
        create(:stale_pack, hungry_man: patr1)
        create(:stale_pack, hungry_man: patr2)
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
    let(:hman) { create(:hman) }

    before(:each) { events.start }
    after(:each) { events.stop }

    it 'creates a thread' do
      expect(events.thread.alive?).to be true
    end

    context 'when stale packages exist,' do
      before(:each) do
        10.times { create(:active_patron) }
        3.times { create(:stale_pack, hungry_man: hman) }
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
