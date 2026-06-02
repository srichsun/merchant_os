require "rails_helper"

# The storefront product grid caches each card (Russian-doll, keyed on
# product.cache_key_with_version). This proves the cache is wired correctly:
# a stale card would still show the old name after an update.
RSpec.describe "Storefront product card caching", type: :request do
  let(:store) { create(:tenant, name: "Demo Store") }

  around do |example|
    was_caching = ActionController::Base.perform_caching
    was_cache = Rails.cache
    ActionController::Base.perform_caching = true
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = was_cache
    ActionController::Base.perform_caching = was_caching
  end

  it "re-renders a product card after the product changes" do
    product = create(:product, tenant: store, name: "Old Name", stock: 5)

    get storefront_store_path(store)
    expect(response.body).to include("Old Name")

    product.update!(name: "New Name")

    get storefront_store_path(store)
    expect(response.body).to include("New Name")
    expect(response.body).not_to include("Old Name")
  end
end
