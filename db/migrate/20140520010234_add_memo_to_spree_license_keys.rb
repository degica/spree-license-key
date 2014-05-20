class AddMemoToSpreeLicenseKeys < ActiveRecord::Migration
  def change
    add_column :spree_license_keys, :memo, :text
  end
end
