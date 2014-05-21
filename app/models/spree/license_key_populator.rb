module Spree
  class LicenseKeyPopulator
    def self.populate(inventory_unit, quantity)
      ActiveRecord::Base.transaction do
        variant = inventory_unit.variant
        license_key_types = variant.license_key_types.empty? ? [nil] : variant.license_key_types
        license_key_types.each do |license_key_type|
          if keys = get_available_keys(inventory_unit, quantity, license_key_type)
            assign_keys!(keys, inventory_unit)
          else
            raise InsufficientLicenseKeys, "Variant: #{inventory_unit.variant.to_param}, License Key Type: #{license_key_type.try(:id)}"
          end
        end
        LicenseKey.where(inventory_unit_id: inventory_unit.id).order('id desc').all
      end
    end

    # Gets keys from source. Should return a relation.
    def self.get_available_keys(inventory_unit, quantity, license_key_type=nil)
      raise NotImplementedError, "Spree::LicenseKeyPopulator must implement a get_available_keys method."
    end

    class InsufficientLicenseKeys < ::StandardError; end

    private

    def self.assign_keys!(keys, inventory_unit)
      keys.each { |key| key.update_attributes!(inventory_unit_id: inventory_unit.id) }
    end
  end
end
