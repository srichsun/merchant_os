require "rails_helper"

RSpec.describe Tenant, type: :model do
  it "is valid with a name" do
    expect(build(:tenant)).to be_valid
  end

  it "requires a name" do
    tenant = build(:tenant, name: nil)
    expect(tenant).not_to be_valid
  end

  it "has many users" do
    tenant = create(:tenant)
    create(:user, tenant: tenant)
    expect(tenant.users.count).to eq(1)
  end
end
