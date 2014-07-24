Spree::Order.class_eval do
  include ActiveSupport::Callbacks

  def electronic_shipments
    shipments.electronic
  end

  def physical_shipments
    shipments.physical
  end

  # from spree_core
  def create_shipment!
    shipping_method(true)

    if line_items.electronically_delivered.any? && electronic_shipments.empty?
      create_shipment_for_shipping_method! Spree::ShippingMethod.electronic
    end

    if line_items.physically_delivered.any?
      if physical_shipments.empty?
        create_shipment_for_shipping_method! shipping_method
      else
        physical_shipments.each do |physical_shipment|
          if physical_shipment.shipping_method != shipping_method
            physical_shipment.update_attributes!(:shipping_method => shipping_method)
          end
        end
      end
    end

    if line_items.electronically_delivered.empty? && electronic_shipments.any?
      electronic_shipments.destroy_all
    end

    if line_items.physically_delivered.empty? && physical_shipments.any?
      physical_shipments.destroy_all
    end

    if inventory_units.electronically_delivered.any?
      electronic_shipments.first.inventory_units = inventory_units.electronically_delivered
    end

    if inventory_units.physically_delivered.any?
      physical_shipments.first.inventory_units = inventory_units.physically_delivered
    end
  end

  def after_finalize!
    electronic_shipments.each do |shipment|
      shipment.delay.ship! if shipment.can_ship?
    end
  end

  private
    def create_shipment_for_shipping_method!(method)
      self.shipments << Spree::Shipment.create!(
        {
          :order => self,
          :shipping_method => method,
          :address => self.ship_address
        },
        :without_protection => true
      )
    end
end
