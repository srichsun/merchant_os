class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :total_cents, null: false, default: 0
      t.string :aasm_state, null: false, default: "pending"

      t.timestamps
    end
  end
end
