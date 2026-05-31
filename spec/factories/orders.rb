FactoryBot.define do
  factory :order do
    tenant
    # keep the product in the same store as the order
    product { association(:product, tenant: tenant) }
    quantity { 1 }
  end
end
