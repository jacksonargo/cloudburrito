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

  context '#valid?' do
    let(:pool) { build(:pool) }
    context 'returns false when' do
      after(:each) { expect(pool.valid?).to be(false) }
      it('name is empty') { pool.name = nil }
      it('name is not unique') { create(:pool, name: pool.name) }
    end
  end

  context '#create!' do
    it 'can be created with patrons' do
      expect(pool_with_patrons.patrons.count).to be 5
    end
  end
end
