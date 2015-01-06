require 'spec_helper'

describe Spree::Order do
  let(:order) { create :order }
  let(:electronic_variant) { create :electronic_variant }
  let(:physical_variant) { create :variant }
  let!(:electronic_shipping_method) { create :shipping_method, :name => Spree::ShippingMethod::electronic_delivery_name }
  let!(:physical_shipping_method) { create :shipping_method }
  before do
    order.shipping_method = physical_shipping_method
  end

  describe '.create_shipment!' do
    context "when there are electronic delivery items" do
      let!(:line_item) { create :line_item, :variant => electronic_variant, :order => order }
      let!(:inventory_unit) { create :inventory_unit, :variant => electronic_variant, :order => order }

      context "when there is not an electronic shipment" do
        it 'add an electronic shipment' do
          expect { order.create_shipment! }.to change{order.electronic_shipments.count}.from(0).to(1)
        end
      end

      it 'adds the inventory units to the first electronic shipment' do
        order.create_shipment!
        order.electronic_shipments.first.inventory_units.should == [inventory_unit]
      end
    end

    context "when there are no electronic delivery items" do
      context "when there is an electronic shipment" do
        let!(:shipment) { create :shipment, :order => order, :shipping_method => electronic_shipping_method }
        before do
          order.shipping_method = electronic_shipping_method
        end

        it "deletes the electronic shipment" do
          expect { order.create_shipment! }.to change{order.electronic_shipments.count}.from(1).to(0)
        end
      end
    end

    context "when there are physical delivery items" do
      let!(:line_item) { create :line_item, :variant => physical_variant, :order => order }
      let!(:inventory_unit) { create :inventory_unit, :variant => physical_variant, :order => order }

      context "when there is not a physical shipment" do
        it 'adds a physical shipment' do
          expect { order.create_shipment! }.to change{order.physical_shipments.count}.from(0).to(1)
        end
      end

      context "when there is a physical shipment" do
        let(:shipment) { create :shipment }
        let(:new_shipping_method) { create :shipping_method }

        before do
          order.shipments << shipment
        end

        context "when the shipping method is different" do
          it "updates the shipping method" do
            order.shipping_method = new_shipping_method
            order.create_shipment!
            order.physical_shipments.first.shipping_method.should == new_shipping_method
          end
        end
      end

      it 'adds the inventory units to the first physical shipment' do
        order.create_shipment!
        order.physical_shipments.first.inventory_units.should == [inventory_unit]
      end
    end

    context "when there are not physical delivery items" do
      context "when there is a physical shipment" do
        let!(:shipment) { create :shipment, :order => order, :shipping_method => physical_shipping_method  }

        it "deletes the physical shipment" do
          expect { order.create_shipment! }.to change{order.physical_shipments.count}.from(1).to(0)
        end
      end
    end

  end

  describe "after update callback", focus:true do
    let!(:shipment) { create :shipment, :order => order, :shipping_method => electronic_shipping_method }
    it "destroys shipments without inventory units" do
      expect {
        order.save!
      }.to change { order.shipments.count }.by(-1)
    end
  end
end
