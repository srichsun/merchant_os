FactoryBot.define do
  factory :product do
    tenant
    sequence(:name) { |n| "Product #{n}" }
    price_cents { 1_000 }
    stock { 10 }
  end
end
