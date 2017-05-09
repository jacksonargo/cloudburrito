require_relative '../../models/message'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Message class' do
  before(:each) do
    Patron.delete_all
    Message.delete_all
    Pool.delete_all
  end

  context '#valid?' do
    context 'returns false when' do
      let(:msg) { build(:message) }
      after(:each) { expect(msg.valid?).to be(false) }
      it('to is nil') { msg.to = nil }
    end
  end

  context '#new' do
    context 'empty message' do
      let(:msg) { build(:message) }
      it('is empty') { expect(msg.text).to eq('') }
      it('not sent') { expect(msg.sent).to be(false) }
    end
    context 'hello message' do
      let(:msg) { build(:hello_msg) }
      it('has text') { expect(msg.text).to eq('Oh hai') }
      it('not sent') { expect(msg.sent).to be(false) }
    end
  end

  context '#sent!' do
    let(:msg) { build(:message) }
    before(:each) { msg.sent! }
    it 'marks message as sent' do
      expect(msg.sent).to be true
    end
    it 'sent_at is not nil' do
      expect(msg.sent_at).not_to be nil
    end
  end
end
