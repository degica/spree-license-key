module Spree
  class LicenseKey < ActiveRecord::Base
    belongs_to :inventory_unit, :class_name => "Spree::InventoryUnit"
    belongs_to :variant, :class_name => "Spree::Variant"
    belongs_to :license_key_type, :class_name => "Spree::LicenseKeyType"

    attr_accessible :license_key, :inventory_unit_id, :variant_id, :void

    scope :available, where(inventory_unit_id: nil, void: false)
    scope :used, where('(inventory_unit_id IS NOT NULL) OR (void IS ?)', true)
  end
end
