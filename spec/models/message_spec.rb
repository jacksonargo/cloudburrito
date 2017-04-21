require_relative '../../models/message'
require 'rspec'

describe "The Message class" do

  def app
    CloudBurrito
  end

  before(:each) do
    Patron.delete_all
    Message.delete_all
  end

  let(:patron) { Patron.create user_id: '1' }

  context 'can be created' do
    let(:msg) { Message.create to: patron, text: "Hi" }
    it('belongs to a patron') { expect(msg.to).to eq(patron) }
    it('has text') { expect(msg.text).to eq("Hi") }
    it('not sent') { expect(msg.sent).to be(false) }
  end

  it 'has empty text string by default' do
    m = Message.create to: patron
    expect(m.text).to eq ''
  end

  context '#sent!' do
    let(:msg) { Message.create to: patron }
    before(:each) { msg.sent! }
    it 'marks message as sent' do
      expect(msg.sent).to be true
    end
    it 'sets sent_at' do
      expect(msg.sent_at).not_to be nil
    end
  end
end
