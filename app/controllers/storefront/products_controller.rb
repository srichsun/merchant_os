module Storefront
  # The public flash-sale drop page for a single product. acts_as_tenant scopes
  # the lookup to this store, so a product id from another store 404s.
  class ProductsController < BaseController
    def show
      @product = Product.find(params[:product_id])
    end
  end
end
