module Storefront
  # Public-facing store pages. No login required, and the tenant is resolved
  # from the URL slug instead of the signed-in user.
  class BaseController < ApplicationController
    layout "storefront"

    skip_before_action :authenticate_user!
    skip_before_action :set_current_tenant
    before_action :set_store

    private

    def set_store
      @store = Tenant.find_by!(slug: params[:store_slug])
      ActsAsTenant.current_tenant = @store
    end
  end
end
