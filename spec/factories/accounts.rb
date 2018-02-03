FactoryGirl.define do
  factory :account do
    sequence(:email) {|n| "subscription#{n}@example.org" }
    password SecureRandom.hex
  end
end

