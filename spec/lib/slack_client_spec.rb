require_relative '../../lib/slack_client'
require 'rspec'

RSpec.describe 'The Slack Client module' do

  def app
    CloudBurrito
  end

  let(:dummy_class) { Class.new { include SlackClient } }
  let(:slack_client) { dummy_class.new }

  it 'should be able to authenticate with slack' do
    expect(slack_client.slack_client.auth_test['ok']).to be true
  end
end
