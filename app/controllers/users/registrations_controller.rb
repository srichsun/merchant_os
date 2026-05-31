module Users
  # On sign up we create the user's store (tenant) and make them its owner.
  class RegistrationsController < Devise::RegistrationsController
    def build_resource(hash = {})
      super
      resource.role = :owner
      # belongs_to saves this new tenant together with the user
      resource.tenant ||= Tenant.new(name: store_name)
    end

    private

    def store_name
      params.dig(:user, :store_name).presence || "My store"
    end
  end
end
