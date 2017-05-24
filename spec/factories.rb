require_relative '../models/message.rb'
require_relative '../models/package.rb'
require_relative '../models/patron.rb'
require_relative '../models/pool.rb'
require_relative '../models/locker.rb'
require 'securerandom'

FactoryGirl.define do
  factory :pool do
    name 'empty_pool'

    # Create a pool with patrons
    factory :pool_with_patrons do
      name 'busy_pool'
      after(:create) do |pool|
        create_list(:patron, 5, pool: pool)
      end
    end

    # Throw patrons in this pool by default
    factory :default_pool do
      name 'default_pool'
    end

    after(:create) do |pool|
      pool.save
    end
  end

  factory :message do
    association :to, factory: :patron
    factory(:hello_msg) { text 'Oh hai' }
  end

  factory :package do

    # A received package
    factory(:received_pack) do
      received true
      en_route true
      assigned true
      failed false
    end

    # A package en route
    factory(:en_route_pack) do
      received false
      en_route true
      assigned true
      failed false
    end

    # An assigned package
    factory(:assigned_pack) do
      received false
      en_route false
      assigned true
      failed false
    end

    # A failed package
    factory(:failed_pack) { failed true }

    # A stale package
    factory(:stale_pack) do
      assigned true
      failed false
      force_stale true
    end

    # A lost package do
    factory(:lost_pack) do
      assigned true
      assigned_at Time.at(0)
      failed false
    end

    before(:create) do |package|
      # Set the default hungry man
      if package.hungry_man.nil?
        create(:hman) unless Patron.where(_id: 'hman').exists?
        package.hungry_man = Patron.find('hman')
      end
      # Set the default delivery man
      if package.delivery_man.nil?
        create(:dman) unless Patron.where(_id: 'dman').exists?
        package.delivery_man = Patron.find('dman')
      end
    end
  end

  # Create a patron
  factory :patron do
    slack_user false

    factory(:active_patron) { active true }

    # Slack patron
    factory(:slack_patron) do
      slack_user_id 'xxx'
      slack_user = true
    end

    # Delivery man
    factory(:dman) do
      slack_user_id 'dman'
      _id 'dman'

      factory(:active_dman) { active true }
    end

    # Hungry man
    factory(:hman) do
      slack_user_id 'hman'
      _id 'hman'

      factory(:active_hman) { active true }
    end

    # Automatically add the patron to a pool, creating the pool if needed.
    before(:create) do |patron|
      if patron.pool.nil?
        create(:default_pool) unless Pool.where(name: 'default_pool').exists?
        patron.pool = Pool.where(name: 'default_pool').first
      end
    end
  end
end
