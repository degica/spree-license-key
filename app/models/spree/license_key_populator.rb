module Spree
  class LicenseKeyPopulator
    attr_reader :variant

    def initialize(variant)
      @variant = variant
    end

    def license_key_types
      variant.license_key_types.empty? ? [nil] : variant.license_key_types
    end

    def populate(inventory_unit, quantity)
      ActiveRecord::Base.transaction do
        license_key_types.each do |license_key_type|
          if keys = get_available_keys(quantity, license_key_type)
            success(inventory_unit, license_key_type)
            assign_keys!(keys, inventory_unit)
          else
            failure(inventory_unit, license_key_type)
          end
        end
        LicenseKey.where(inventory_unit_id: inventory_unit.id).order('id desc').all
      end
    end

    # Gets keys from source. Should return a relation.
    def get_available_keys(quantity, license_key_type=nil)
      raise NotImplementedError, "Spree::LicenseKeyPopulator must implement a get_available_keys method."
    end

    def failure(inventory_unit, license_key_type)
    end

    def success(inventory_unit, license_key_type)
    end

    class InsufficientLicenseKeys < ::StandardError; end

    private

    def assign_keys!(keys, inventory_unit)
      timestamp = DateTime.now
      keys.each { |key| key.update_attributes!(inventory_unit_id: inventory_unit.id, activated_on: timestamp) }
    end
  end
end
