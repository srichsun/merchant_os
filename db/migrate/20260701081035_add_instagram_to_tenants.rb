class AddInstagramToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :instagram_handle, :string
    add_column :tenants, :verified, :boolean, default: false, null: false
  end
end
