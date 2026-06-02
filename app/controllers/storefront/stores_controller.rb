module Storefront
  class StoresController < BaseController
    def show
      # Buyer just came back from Stripe's hosted checkout.
      if params[:checkout] == "success"
        flash.now[:notice] = "Payment received — your order is confirmed and a receipt email is on its way."
      end

      # Only in-stock products; scoped to this store by acts_as_tenant.
      # with_attached_image preloads photos so the grid doesn't N+1.
      @products = Product.where("stock > 0").with_attached_image
      @products =
        if params[:q].present?
          @products.search_by_name(params[:q])
        else
          @products.order(:name)
        end
    end
  end
end
