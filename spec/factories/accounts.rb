FactoryBot.define do
  factory :account do
    sequence(:email) { |n| "subscription#{n}@example.org" }
    password { SecureRandom.hex }

    trait :as_superadmin do
      email { 'api-superadmin@localhost' }
      api_superadmin { true }
    end

    factory :superadmin_account, traits: [:as_superadmin]
  end
end
