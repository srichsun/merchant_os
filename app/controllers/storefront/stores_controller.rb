module Storefront
  class StoresController < BaseController
    def show
      # Only in-stock products; scoped to this store by acts_as_tenant
      @products = Product.where("stock > 0")
      @products =
        if params[:q].present?
          @products.search_by_name(params[:q])
        else
          @products.order(:name)
        end
    end
  end
end
