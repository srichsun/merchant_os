class AddPaymentRefToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :payment_ref, :string
  end
end
