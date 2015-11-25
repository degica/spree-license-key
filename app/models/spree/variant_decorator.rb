Spree::Variant.class_eval do
  has_many :license_keys, class_name: 'Spree::LicenseKey'
  has_and_belongs_to_many :license_key_types, :join_table => :spree_variant_license_key_types, :class_name => "Spree::LicenseKeyType"

  attr_accessible :electronic_delivery_keys, :electronic_delivery

  validate :electronic_delivery_set

  def license_key_populator_class
    populator_type.present? ? populator_type.try(:constantize) : Spree::DefaultLicenseKeyPopulator
  end

  def license_key_populator
    license_key_populator_class.new(self)
  end

  def on_hand_with_on_hand_of_electronic_delivery
    if electronic_delivery?
      license_key_populator.on_hand
    else
      on_hand_without_on_hand_of_electronic_delivery
    end
  end
  alias_method_chain :on_hand, :on_hand_of_electronic_delivery

  private
  def electronic_delivery_set
    if electronic_delivery_keys && electronic_delivery_keys > 0 && !electronic_delivery?
      errors.add(:electronic_delivery, I18n.t('spree.variant.electronic_delivery_setting_error'))
    end
  end
end
