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

  describe "instagram" do
    it "stores the bare handle, stripping a leading @ and spaces" do
      tenant = create(:tenant, instagram_handle: " @dane ")
      expect(tenant.instagram_handle).to eq("dane")
    end

    it "builds a link to the public profile" do
      tenant = create(:tenant, instagram_handle: "howtobeast")
      expect(tenant.instagram_url).to eq("https://www.instagram.com/howtobeast/")
    end

    it "has no url when there's no handle" do
      expect(create(:tenant, instagram_handle: nil).instagram_url).to be_nil
    end
  end
end
