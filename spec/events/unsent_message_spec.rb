# frozen_string_literal: true

require_relative '../../events/unsent_message'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'Event::UnsentMessage' do
  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Message.delete_all
    Locker.delete_all
  end

  let(:events) { Event::UnsentMessage.new }
  let(:patron) { create(:patron) }

  context 'initialize' do
    it 'creates a slack client' do
      expect(events.slack_client).not_to be nil
    end
  end

  context '#unsent_messages' do
    it 'empty if there are no messages' do
      expect(events.unsent_messages).to be_empty
    end
    it 'empty if there are no unsent messages' do
      Message.create to: patron, sent: true
      expect(events.unsent_messages).to be_empty
    end
    it 'not empty if there are unsent messages' do
      Message.create to: patron
      expect(events.unsent_messages).not_to be_empty
    end
    it 'returns unsent messages' do
      m = Message.create to: patron
      expect(events.unsent_messages.first).to eq m
    end
  end

  context '#send_slack_pm' do
    let(:msg) { Message.create to: patron }
    it 'sends successfully method' do
      success = events.send_slack_pm msg
      expect(success).to be true
    end
  end

  context '#send_next' do
    context 'no messages exist' do
      before(:each) { events.send_next }
      it 'doesnt fail' do
      end
    end

    context 'the message is locked' do
      let(:msg) { Message.create to: patron }
      before(:each) { Locker.lock msg }
      it 'does not send message' do
        events.send_next
        expect(msg.sent).to be false
      end
    end

    context 'one message exists' do
      before(:each) do
        Message.create to: patron
        events.send_next
      end

      it 'the first is marked sent' do
        expect(Message.first.sent).to be true
      end

      it 'there are no unsent messages left' do
        expect(events.unsent_messages.exists?).to be false
      end

      it 'the message is not locked' do
        expect(Locker.unlock(Message.first)).to be false
      end
    end

    context 'two messages exist' do
      before(:each) do
        2.times { Message.create to: patron }
        events.send_next
      end

      context 'processes them first in fist out' do
        it 'first should be sent' do
          expect(Message.first.sent).to be true
        end
        it 'last should not be sent' do
          expect(Message.last.sent).to be false
        end
        it 'only one unsent message' do
          expect(events.unsent_messages.count).to be 1
        end
        it 'first unsent message is now the last message' do
          m = Message.last
          expect(events.unsent_messages.first).to eq m
        end
      end
    end
  end

  context '#start' do
    before(:each) { events.start }
    after(:each) { events.stop }

    it 'creates a thread' do
      expect(events.thread.alive?).to be true
    end

    context 'when unsent messages exist' do
      before(:each) do
        3.times { Message.create to: patron }
      end
      it 'marks them sent' do
        events.wait_for_complete
        expect(Message.where(sent: true).count).to be 3
      end
    end
  end

  context '#wait_for_complete' do
    it 'returns when no unsent messages exist' do
      events.start
      events.wait_for_complete
      expect(events.unsent_messages).to be_empty
      events.stop
    end
  end
end
