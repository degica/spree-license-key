class AddVoidToSpreeLicenseKeys < ActiveRecord::Migration
  def change
    add_column :spree_license_keys, :void, :boolean, :default => false
  end
end
