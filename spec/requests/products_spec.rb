require "rails_helper"

RSpec.describe "Products", type: :request do
  let(:tenant) { create(:tenant) }
  let(:owner) { create(:user, tenant: tenant, role: :owner) }

  describe "GET /products" do
    it "shows only the current store's products" do
      mine = create(:product, tenant: tenant, name: "My Mug")
      theirs = create(:product, tenant: create(:tenant), name: "Other Store Mug")
      sign_in owner

      get products_path

      expect(response.body).to include(mine.name)
      expect(response.body).not_to include(theirs.name)
    end
  end

  describe "POST /products" do
    it "creates a product in the current store" do
      sign_in owner

      expect do
        post products_path, params: { product: { name: "Mug", price_cents: 500, stock: 3 } }
      end.to change(tenant.products, :count).by(1)
    end
  end

  describe "DELETE /products/:id" do
    it "lets an owner delete a product" do
      product = create(:product, tenant: tenant)
      sign_in owner

      delete product_path(product)

      expect(Product.exists?(product.id)).to be(false)
    end

    it "forbids a staff member from deleting" do
      product = create(:product, tenant: tenant)
      staff = create(:user, tenant: tenant, role: :staff)
      sign_in staff

      delete product_path(product)

      expect(response).to redirect_to(root_path)
      expect(Product.exists?(product.id)).to be(true)
    end
  end
end
