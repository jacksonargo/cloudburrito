require_relative '../models/message.rb'
require_relative '../models/package.rb'
require_relative '../models/patron.rb'
require_relative '../models/pool.rb'
require_relative '../models/locker.rb'
require 'securerandom'

FactoryGirl.define do
  factory :pool do
    _id 'empty_pool'
    name 'empty_pool'

    # Create a pool with patrons
    factory :pool_with_patrons do
      _id 'busy_pool'
      name 'busy_pool'
      after(:create) do |pool|
        create_list(:patron, 5, pool: pool)
      end
    end

    # Throw patrons in this pool by default
    factory :default_pool do
      _id 'default_pool'
      name 'default_pool'
    end
  end

  factory :message do
    association :to, factory: :valid_patron
    factory(:hello_msg) { text 'Oh hai' }
  end

  factory :package do
    association :hungry_man, factory: :hman
    association :delivery_man, factory: :dman

    factory(:received_pack) { received true }
    factory(:en_route_pack) { en_route true }
    factory(:assigned_pack) { assigned true }
    factory(:failed_pack) { failed true }
  end

  # Create a patron
  factory :patron do

    # Invalid patrons do not have a pool
    factory(:invalid_patron) { pool nil }

    # Valid patrons are in a pool
    factory :valid_patron do
      # Delivery man
      factory(:dman) do
        user_id 'dman'
        _id 'dman'
      end

      # Hungry man
      factory(:hman) do
        user_id 'hman'
        _id 'hman'
      end

      # Automatically add the patron to a pool, creating the pool if needed.
      before(:create) do |patron|
        if patron.pool.nil?
          create(:default_pool) unless Pool.where(name: 'default_pool').exists?
          patron.pool = Pool.find('default_pool')
        end
      end
    end
  end
end
