FactoryBot.define do
  factory :tenant do
    sequence(:name) { |n| "Store #{n}" }
  end
end
