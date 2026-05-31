class AddSlugToTenants < ActiveRecord::Migration[8.1]
  def up
    add_column :tenants, :slug, :string

    # Backfill existing stores so their public storefront URL works
    Tenant.reset_column_information
    Tenant.find_each { |t| t.update_columns(slug: t.name.parameterize) }

    # Tiny table in this demo, so the plain index is fine
    safety_assured { add_index :tenants, :slug, unique: true }
  end

  def down
    remove_column :tenants, :slug
  end
end
