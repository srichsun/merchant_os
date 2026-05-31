# Demo data. Idempotent: safe to run repeatedly (find_or_create_by everywhere).
# Two separate stores so the multi-tenant isolation is visible after login.
#
# Logins (password "password123"):
#   owner@example.com  / staff@example.com   -> Demo Store
#   owner2@example.com                        -> Coffee Lab

def seed_store(name:, owner_email:, staff_email: nil, products:)
  store = Tenant.find_or_create_by!(name: name)

  User.find_or_create_by!(email: owner_email) do |u|
    u.tenant = store
    u.password = "password123"
    u.role = :owner
  end

  if staff_email
    User.find_or_create_by!(email: staff_email) do |u|
      u.tenant = store
      u.password = "password123"
      u.role = :staff
    end
  end

  products.each do |attrs|
    store.products.find_or_create_by!(name: attrs[:name]) do |p|
      p.price_cents = attrs[:price_cents]
      p.stock = attrs[:stock]
    end
  end

  store
end

demo = seed_store(
  name: "Demo Store",
  owner_email: "owner@example.com",
  staff_email: "staff@example.com",
  products: [
    { name: "Cold Brew Coffee", price_cents: 12_000, stock: 50 },
    { name: "Ceramic Mug",      price_cents: 38_000, stock: 20 },
    { name: "Tote Bag",         price_cents: 25_000, stock: 0 } # sold out
  ]
)

seed_store(
  name: "Coffee Lab",
  owner_email: "owner2@example.com",
  products: [
    { name: "Espresso Beans 1kg", price_cents: 60_000, stock: 30 },
    { name: "Pour-over Kettle",   price_cents: 95_000, stock: 8 }
  ]
)

# A few orders in different states for the Demo Store
if demo.orders.none?
  mug = demo.products.find_by!(name: "Ceramic Mug")
  coffee = demo.products.find_by!(name: "Cold Brew Coffee")

  Order.create!(tenant: demo, product: coffee, quantity: 1) # pending
  Order.create!(tenant: demo, product: mug, quantity: 2, aasm_state: "paid")
  Order.create!(tenant: demo, product: coffee, quantity: 3, aasm_state: "shipped")
end

puts "Seeded #{Tenant.count} stores, #{User.count} users, " \
     "#{Product.count} products, #{Order.count} orders."
