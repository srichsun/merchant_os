class AddCustomerToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :customer_email, :string
  end
end
