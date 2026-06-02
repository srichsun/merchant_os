class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      # Speed up pg_search trigram search on product names (seq scan -> index scan)
      add_index :products, :name, using: :gin, opclass: :gin_trgm_ops,
                name: "index_products_on_name_trigram"

      # The ECPay webhook looks orders up by this
      add_index :orders, :payment_ref

      # Dashboard / orders list: scoped to a store, ordered by recency
      add_index :orders, [ :tenant_id, :created_at ]
    end
  end
end
