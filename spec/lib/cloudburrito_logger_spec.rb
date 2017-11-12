# frozen_string_literal: true

require_relative '../../lib/cloudburrito_logger'
require 'rspec'

RSpec.describe 'The CloudBurritoLogger module' do
  def app
    CloudBurrito
  end
end
