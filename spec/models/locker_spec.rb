# frozen_string_literal: true

require_relative '../../models/locker'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'The Locker class' do
  def app
    CloudBurrito
  end

  before(:each) do
    Locker.delete_all
  end

  let(:dummy_model) { Class.new { include Mongoid::Document } }
  let(:model) { dummy_model.new }

  context '::lock' do
    context 'lock already exists' do
      before(:each) { Locker.lock model }
      it 'returns false' do
        expect(Locker.lock(model)).to be false
      end
    end
    context 'lock does not exist' do
      it 'creates the lock' do
        Locker.lock model
        expect(Locker.count).to be 1
      end
      it 'id is combo of model class and id' do
        Locker.lock model
        expect(Locker.first._id).to eq(model.class.to_s + model._id.to_s)
      end
      it 'returns true' do
        expect(Locker.lock(model)).to be true
      end
    end
  end

  context '::unlock' do
    context 'lock does not exist' do
      it 'returns false' do
        expect(Locker.unlock(model)).to be false
      end
    end
    context 'lock exists' do
      before(:each) { Locker.lock model }
      it 'lock is deleted' do
        Locker.unlock model
        expect(Locker.count).to be 0
      end
      it 'returns true' do
        expect(Locker.unlock(model)).to be true
      end
    end
  end
end
