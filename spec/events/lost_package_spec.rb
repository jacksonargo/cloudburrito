# frozen_string_literal: true

require_relative '../../events/lost_package'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'Event::LostPackage' do
  before(:each) do
    Patron.delete_all
    Package.delete_all
    Message.delete_all
  end

  let(:events) { Event::LostPackage.new }

  context '#lost_packages' do
    context 'no packages' do
      it('returns []') { expect(events.lost_packages).to eq([]) }
    end

    context 'packages exist' do
      before(:each) { create(:package) }

      context 'no assigned packages' do
        it('returns []') { expect(events.lost_packages).to eq([]) }
      end

      context 'assigned packages exist' do
        before(:each) { create(:assigned_pack) }
        context 'no lost packages' do
          it('returns []') { expect(events.lost_packages).to eq([]) }
        end

        context 'lost package exist' do
          before(:each) { create(:lost_pack) }
          it('doesnt return []') { expect(events.lost_packages).not_to eq([]) }
          it('returns lost packages') do
            expect(events.lost_packages).to eq([Package.last])
          end
        end
      end
    end
  end

  context '#fail_next' do
    context 'no packages exist' do
      before(:each) { events.fail_next }
      it 'doesnt fail' do
      end
    end

    context 'one package becomes lost' do
      let(:hman) { create(:hman) }
      let(:dman) { create(:dman) }
      before(:each) { create(:lost_pack, hungry_man: hman, delivery_man: dman) }

      context 'the package is locked' do
        before(:each) do
          Locker.lock Package.first
          events.fail_next
        end
        it 'is not modified' do
          expect(events.lost_packages.count).to be 1
        end
      end

      context 'the package is not locked' do
        before(:each) { events.fail_next }
        it 'the first package is no longer lost' do
          expect(Package.first.lost?).to be false
        end

        it 'the package is not locked' do
          expect(Locker.unlock(Package.first)).to be false
        end

        it 'there are no lost packages' do
          expect(events.lost_packages).to eq []
        end

        it 'marks the package as failed' do
          expect(Package.first.failed?).to be true
        end

        it 'the new package is not lost' do
          expect(Package.last.lost?).to be false
        end

        context 'creates messages' do
          context 'for delivery man' do
            let(:message) { Message.where(to: dman).last }
            it('exists') { expect(message).not_to be(nil) }
            it('says the burrito was lost') do
              text = "It appears <@#{hman.slack_user_id}> never received the burrito. "
              text += "Since it has been an hour, you can order burritos again, but you don't get points for the last delivery."
              expect(message.text).to eq text
            end
          end
          context 'for hungry man' do
            let(:message) { Message.where(to: hman).last }
            it('exists') { expect(message).not_to be(nil) }
            it('says the burrito was lost') do
              text = "It doesn't look like you received your burrito. "
              text += 'Since it has been an hour, you can order another burrito. '
              text += 'When you receive the burrito, be sure to tell Cloudburrito with _/cloudburrito full_ or you wont get points.'
              expect(message.text).to eq text
            end
          end
        end
      end
    end

    context 'two packages become lost' do
      let(:patr1) { create(:patron) }
      let(:patr2) { create(:patron) }
      before(:each) do
        create(:lost_pack, hungry_man: patr1)
        create(:lost_pack, hungry_man: patr2)
        events.fail_next
      end

      context 'processes them first in fist out' do
        it 'first package should be failed' do
          expect(Package.first.failed).to be true
        end
        it 'next lost package is different from first package' do
          expect(events.lost_packages.first).not_to eq(Package.first)
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

    context 'when lost packages exist,' do
      before(:each) do
        10.times { create(:active_patron) }
        3.times { create(:lost_pack, hungry_man: hman) }
      end
      it 'marks them failed' do
        events.wait_for_complete
        expect(Package.where(failed: true).count).to be 3
      end
    end
  end

  context '#wait_for_complete' do
    it 'returns when no more lost packages' do
      events.start
      events.wait_for_complete
      expect(events.lost_packages).to eq []
      events.stop
    end
  end
end
