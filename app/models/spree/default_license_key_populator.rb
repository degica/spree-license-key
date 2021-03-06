module Spree
  class DefaultLicenseKeyPopulator < LicenseKeyPopulator

    def get_available_keys(inventory_unit, quantity, license_key_type=nil)
      return false unless count_available(license_key_type) >= quantity
      LicenseKey.available.where(
        :variant_id => variant.id,
        :license_key_type_id => license_key_type.try(:id)
      ).order('id asc').limit(quantity).lock
    end

    def failure(inventory_unit, license_key_type)
      raise(InsufficientLicenseKeys,
            "Variant: #{inventory_unit.variant.to_param}, License Key Type: #{license_key_type.try(:id)}")
    end

    def on_hand
      return Float::INFINITY unless variant.electronic_delivery_keys.to_i > 0
      license_key_types.map { |type| count_available(type) }.min
    end

    private

    def count_available(license_key_type)
      relation = license_key_type ? license_key_type.available : Spree::LicenseKey.available.where(license_key_type_id: nil)
      relation.where(variant_id: variant.try(:id)).count
    end
  end
end
