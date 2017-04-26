FactoryGirl.define do
  faction :pool do
    name 'test_pool'
  end

  factory :patron do
    user_id '1'
    pool Pool.find('test_pool')
  end

  factory :hman, class: Patron do
  end

  factory :dman, class: Patron do
  end

  factory :message do
  end

  factory :package do
  end
end
