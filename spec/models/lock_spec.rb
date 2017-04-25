require_relative '../../models/package'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Lock class' do
  def app
    CloudBurrito
  end

  before(:each) do
    Lock.delete_all
  end
end
