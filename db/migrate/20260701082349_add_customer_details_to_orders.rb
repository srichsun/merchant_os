class AddCustomerDetailsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :customer_name, :string
    add_column :orders, :phone, :string
    add_column :orders, :shipping_address, :text
  end
end
