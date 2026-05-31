class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      # Money is stored as an integer in the smallest unit, never as a float
      t.integer :price_cents, null: false, default: 0
      t.integer :stock, null: false, default: 0

      t.timestamps
    end
  end
end
