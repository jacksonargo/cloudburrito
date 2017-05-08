require_relative '../../models/message'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Message class' do
  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Message.delete_all
    Pool.delete_all
  end

  let(:patron) { create(:valid_patron) }

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
