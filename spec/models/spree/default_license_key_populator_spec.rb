require 'spec_helper'

describe Spree::DefaultLicenseKeyPopulator do
  let(:inventory_unit) { build_stubbed :inventory_unit, variant: variant }
  let(:variant) { nil }
  let(:quantity) { 2 }
  let(:populator) { described_class.new(variant) }

  describe '#get_available_keys' do
    shared_examples_for "license key populator" do
      context "no keys available" do
        it "returns false" do
          populator.get_available_keys(inventory_unit, quantity, license_key_type).should == false
        end
      end

      context "keys available" do
        let(:variant) { create :variant }
        let!(:license_keys) { quantity.times.map { create(:license_key, variant: variant, license_key_type: license_key_type) } }

        it "returns license keys with this type" do
          populator.get_available_keys(inventory_unit, quantity, license_key_type).should == license_keys
        end

        it "only returns license keys with this type" do
          other_license_key_type = create :license_key_type
          other_license_keys = quantity.times.map { create :license_key, variant: variant, license_key_type: other_license_key_type }
          populator.get_available_keys(inventory_unit, quantity, other_license_key_type).should == other_license_keys
        end

        it "only returns license keys without inventory ids" do
          license_keys.each { |key| key.update_attributes!(inventory_unit_id: inventory_unit.id) }
          other_license_keys = quantity.times.map { create :license_key, variant: variant, license_key_type: license_key_type }
          populator.get_available_keys(inventory_unit, quantity, license_key_type).should == other_license_keys
        end

        it "only returns license keys that are not void" do
          license_keys.each { |key| key.update_attributes!(void: true) }
          other_license_keys = quantity.times.map { create :license_key, variant: variant, license_key_type: license_key_type }
          populator.get_available_keys(inventory_unit, quantity, license_key_type).should == other_license_keys
        end
      end
    end

    context "nil license key type" do
      let(:license_key_type) { nil }
      it_behaves_like "license key populator"
    end

    context "license key type defined" do
      let(:license_key_type) { create(:license_key_type) }
      it_behaves_like "license key populator"
    end
  end

  describe 'failure callback' do
    let(:variant) { build_stubbed :variant }
    it "raises error for insufficient keys if none are available" do
      expect { populator.populate(inventory_unit, quantity + 1) }.to raise_error(Spree::LicenseKeyPopulator::InsufficientLicenseKeys)
    end
  end

  describe '#on_hand' do
    let(:electronic_delivery_keys) { 1 }
    let(:variant) { create :variant, electronic_delivery_keys: electronic_delivery_keys, electronic_delivery: true }

    context "no keys on variant" do
      let(:electronic_delivery_keys) { 0 }

      it "returns infinity" do
        expect(populator.on_hand).to eq(Float::INFINITY)
      end
    end

    context "nil license key type" do
      before do
        quantity.times.map { create(:license_key, variant: variant, license_key_type: nil) }
      end

      it "returns number of remaining keys" do
        expect(populator.on_hand).to eq(2)
      end
    end

    context "license key types defined" do
      let(:license_key_type) { create(:license_key_type) }
      before do
        license_key_type_1 = create(:license_key_type, variants: [variant])
        create(:license_key, variant: variant, license_key_type: license_key_type_1)
        license_key_type_2 = create(:license_key_type, variants: [variant])
        2.times { create(:license_key, variant: variant, license_key_type: license_key_type_2) }
      end

      it "returns minimum number of remaining keys across all types" do
        expect(populator.on_hand).to eq(1)
      end
    end
  end
end
