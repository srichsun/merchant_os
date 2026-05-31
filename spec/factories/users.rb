FactoryBot.define do
  factory :user do
    tenant
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :owner }
  end
end
