# Demo data. Idempotent: safe to run repeatedly (find_or_create_by everywhere).
# Two separate stores so the multi-tenant isolation is visible after login.
#
# Logins (password "password123"):
#   owner@example.com  / staff@example.com   -> Demo Store
#   owner2@example.com                        -> Coffee Lab

# Attach the product's demo photo (db/seeds/images/<filename>). Wrapped in a
# rescue so a missing/misconfigured object store never breaks the boot-time seed.
def attach_demo_image(product, filename)
  return if filename.blank?

  path = Rails.root.join("db/seeds/images", filename)
  return unless File.exist?(path)

  unless product.image.attached? && product.image.blob.filename.to_s == filename && demo_image_present?(product)
    product.image.purge if product.image.attached?
    product.image.attach(io: File.open(path), filename: filename, content_type: "image/jpeg")
  end

  # Pre-generate the :card thumbnail now so the storefront serves a ready-made
  # variant instead of processing it on the first request (visible lag otherwise).
  product.image.variant(:card).processed
rescue => e
  warn "Skipped image for #{product.name}: #{e.message}"
end

# True only if the attached original actually exists on the current service.
def demo_image_present?(product)
  blob = product.image.blob
  blob.service_name.to_s == ActiveStorage::Blob.service.name.to_s && blob.service.exist?(blob.key)
rescue StandardError
  false
end

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
    product = store.products.find_or_create_by!(name: attrs[:name]) do |p|
      p.price_cents = attrs[:price_cents]
      p.stock = attrs[:stock]
    end
    attach_demo_image(product, attrs[:image])
  end

  store
end

demo = seed_store(
  name: "Demo Store",
  owner_email: "owner@example.com",
  staff_email: "staff@example.com",
  products: [
    { name: "Cold Brew Coffee",   price_cents: 12_000, stock: 50, image: "cold-brew-coffee.jpg" },
    { name: "Ceramic Mug",        price_cents: 38_000, stock: 20, image: "ceramic-mug.jpg" },
    { name: "Pour-over Dripper",  price_cents: 45_000, stock: 15, image: "pour-over-dripper.jpg" },
    { name: "Paper Filters ×100", price_cents: 18_000, stock: 80, image: "paper-filters.jpg" },
    { name: "Stainless Tumbler",  price_cents: 52_000, stock: 12, image: "stainless-tumbler.jpg" },
    { name: "Coffee Beans 250g",  price_cents: 36_000, stock: 40, image: "coffee-beans.jpg" },
    { name: "Gift Box Set",       price_cents: 88_000, stock: 8, image: "gift-box-set.jpg" },
    { name: "Tote Bag",           price_cents: 25_000, stock: 0, image: "tote-bag.jpg" } # sold out
  ]
)

seed_store(
  name: "Coffee Lab",
  owner_email: "owner2@example.com",
  products: [
    { name: "Espresso Beans 1kg", price_cents: 60_000, stock: 30, image: "espresso-beans.jpg" },
    { name: "Pour-over Kettle",   price_cents: 95_000, stock: 8, image: "pour-over-kettle.jpg" },
    { name: "Milk Frother",       price_cents: 42_000, stock: 18, image: "milk-frother.jpg" }
  ]
)

# A spread of orders for the Demo Store so the dashboard and the paginated
# orders page have something to show.
if demo.orders.none?
  products = demo.products.to_a
  emails = %w[alice bob carol dave erin frank grace heidi ivan judy].map { |n| "#{n}@example.com" }

  28.times do
    Order.create!(
      tenant: demo,
      product: products.sample,
      quantity: rand(1..3),
      customer_email: emails.sample,
      aasm_state: %w[paid paid paid shipped shipped pending].sample,
      created_at: rand(0..21).days.ago
    )
  end
end

puts "Seeded #{Tenant.count} stores, #{User.count} users, " \
     "#{Product.count} products, #{Order.count} orders."
