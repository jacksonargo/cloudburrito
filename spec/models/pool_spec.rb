require_relative '../../models/pool'
require 'rspec'

Mongoid.load!('config/mongoid.yml')

RSpec.describe 'Pool model' do
  before(:each) do
    Pool.delete_all
    Patron.delete_all
  end

  let(:pool) { create(:pool) }
  let(:pool_with_patrons) { create(:pool_with_patrons) }

  context '#create' do
    it 'can be saved' do
      expect(pool.save).to be true
    end

    it 'can be created with patrons' do
      expect(pool_with_patrons.patrons.count).to be 5
    end

    context '_id not specificied' do
      let(:pool) { create(:pool, name: 'fancy') }
      before(:each) { pool.reload }
      it('_id equals name') { expect(pool._id).to eq(pool.name) }
    end
  end
end
