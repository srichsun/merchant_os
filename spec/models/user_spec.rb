require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with the factory" do
    expect(build(:user)).to be_valid
  end

  it "belongs to a tenant" do
    expect(build(:user, tenant: nil)).not_to be_valid
  end

  it "requires an email" do
    expect(build(:user, email: nil)).not_to be_valid
  end

  it "defaults to the owner role" do
    expect(create(:user).role).to eq("owner")
  end

  it "can be a staff member" do
    expect(build(:user, role: :staff)).to be_staff
  end
end
