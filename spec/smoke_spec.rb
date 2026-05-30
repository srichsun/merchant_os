require "rails_helper"

# Smoke test: proves the app boots in the test env and the database is wired up
# (rails_helper checks the test schema on load). Replace once real specs exist.
RSpec.describe "Application boot" do
  it "runs in the test environment" do
    expect(Rails.env).to eq("test")
  end

  it "can reach the database" do
    expect { ActiveRecord::Base.connection.execute("SELECT 1") }.not_to raise_error
  end
end
