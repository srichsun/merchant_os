require "rails_helper"

RSpec.describe "Sign up", type: :request do
  it "creates a store and an owner user" do
    expect do
      post user_registration_path, params: {
        user: { store_name: "Dane's Shop", email: "dane@example.com", password: "password123" }
      }
    end.to change(Tenant, :count).by(1).and change(User, :count).by(1)

    user = User.find_by(email: "dane@example.com")
    expect(user.tenant.name).to eq("Dane's Shop")
    expect(user).to be_owner
  end
end
