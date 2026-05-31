require "rails_helper"

RSpec.describe "Storefront", type: :request do
  let(:store) { create(:tenant, name: "Demo Store") }

  describe "GET /s/:slug" do
    it "is public (no login) and shows in-stock products" do
      in_stock = create(:product, tenant: store, name: "Mug", stock: 5)
      sold_out = create(:product, tenant: store, name: "Tote", stock: 0)

      get storefront_store_path(store)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(in_stock.name)
      expect(response.body).not_to include(sold_out.name)
    end

    it "shows only this store's products" do
      mine = create(:product, tenant: store, name: "My Mug", stock: 5)
      theirs = create(:product, tenant: create(:tenant), name: "Their Mug", stock: 5)

      get storefront_store_path(store)

      expect(response.body).to include(mine.name)
      expect(response.body).not_to include(theirs.name)
    end

    it "filters by the search query" do
      create(:product, tenant: store, name: "Ceramic Mug", stock: 5)
      create(:product, tenant: store, name: "Wooden Spoon", stock: 5)

      get storefront_store_path(store), params: { q: "ceramic" }

      expect(response.body).to include("Ceramic Mug")
      expect(response.body).not_to include("Wooden Spoon")
    end
  end

  describe "POST /s/:slug/orders" do
    it "places a paid order and takes stock" do
      product = create(:product, tenant: store, stock: 3)

      expect do
        post storefront_store_orders_path(store, product_id: product.id)
      end.to change { store.orders.where(aasm_state: "paid").count }.by(1)

      expect(product.reload.stock).to eq(2)
    end

    it "shows a sold-out message when there's no stock" do
      product = create(:product, tenant: store, stock: 0)

      post storefront_store_orders_path(store, product_id: product.id)

      expect(response).to redirect_to(storefront_store_path(store))
      follow_redirect!
      expect(response.body).to include("sold out")
    end
  end
end
