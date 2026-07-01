require "rails_helper"

RSpec.describe "Storefront product drop page", type: :request do
  let(:store) { create(:tenant, name: "Star Creator") }

  it "renders the drop page with limited price, discount and buy action" do
    product = ActsAsTenant.with_tenant(store) do
      create(:product, tenant: store, name: "Limited Hoodie",
             price_cents: 750, original_price_cents: 1_000, stock: 5,
             sale_starts_at: 1.hour.ago, sale_ends_at: 1.hour.from_now)
    end

    get storefront_store_product_path(store.slug, product.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Limited Hoodie", "Buy now", "25% off", "left")
  end

  it "disables buying once the sale has ended" do
    product = ActsAsTenant.with_tenant(store) do
      create(:product, tenant: store, sale_ends_at: 1.hour.ago)
    end

    get storefront_store_product_path(store.slug, product.id)

    expect(response.body).to include("Sale ended")
    expect(response.body).not_to include("Buy now")
  end
end
