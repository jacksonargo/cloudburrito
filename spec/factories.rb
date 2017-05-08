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
    factory :pool_with_patrons do
      _id 'busy_pool'
      name 'busy_pool'
      after(:create) do |pool|
        print pool.attributes
        create_list(:patron, 5, pool: pool)
      end
    end
  end

  factory :message do
    association :to, factory: :patron
    factory(:hello_msg) { text 'Oh hai' }
  end

  factory :package do
    association :hungry_man, factory: :patron
    association :delivery_man, factory: :patron

    factory(:received_pack) { received true }
    factory(:en_route_pack) { en_route true }
    factory(:assigned_pack) { assigned true }
    factory(:failed_pack) { failed true }
  end

  factory :patron do
    pool
  end
end
