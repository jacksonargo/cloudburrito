require_relative '../../cloudburrito'
require 'rspec'
require 'rack/test'

describe "Message class" do
  include Rack::Test::Methods

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
  end
end
