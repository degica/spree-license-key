require 'spec_helper'
require 'timecop'

describe Spree::LicenseKeyPopulator do
  describe '.populate' do
    let(:inventory_unit) { build_stubbed :inventory_unit, variant: variant }
    let(:variant) { nil }
    let(:quantity) { 2 }
    let(:license_key_populator) { Spree::LicenseKeyPopulator.new(variant) }

    describe ".get_available_keys" do
      it "raises NotImplementedError" do
        populator = Spree::LicenseKeyPopulator.new(variant)
        expect {
          populator.get_available_keys(quantity)
        }.to raise_error(NotImplementedError)
      end
    end

    describe ".populate" do
      before { quantity.times { create :license_key } }
      let(:populator_class) do
        Class.new(Spree::LicenseKeyPopulator) do
          # Minimal populator function, returns false if there are not enough keys.
          def get_available_keys(quantity, license_key_type=nil)
            quantity <= Spree::LicenseKey.count ? Spree::LicenseKey.scoped : false
          end
        end
      end
      let(:populator) { populator_class.new(variant) }

      shared_examples_for "license key populator" do
        it "assigns inventory unit id to each license key" do
          keys = populator.populate(inventory_unit, quantity)
          keys.each { |key| key.inventory_unit_id.should == inventory_unit.id }
        end

        it "sets activated_on on license keys when they are assigned" do
          t = Date.today + 5
          keys = Timecop.freeze(t) { populator.populate(inventory_unit, quantity) }
          keys.each { |key| key.activated_on.should == t }
        end

        describe 'success/failure callbacks' do
          # if no license key types, check that callbacks are called with nil
          let(:license_key_types) do
            if !inventory_unit.variant.license_key_types.empty?
              inventory_unit.variant.license_key_types
            else
              [ nil ]
            end
          end

          it "calls success" do
            license_key_types.each do |license_key_type|
              populator.should_receive(:success).once.with(inventory_unit, license_key_type)
            end
            populator.populate(inventory_unit, quantity)
          end

          it "calls failure" do
            license_key_types.each do |license_key_type|
              populator.should_receive(:failure).once.with(inventory_unit, license_key_type)
            end
            populator.populate(inventory_unit, quantity + 1)
          end
        end

      end

      context "variant has no license key types" do
        let(:variant) { build_stubbed :variant }

        it_behaves_like "license key populator"

        it "calls get_available_keys once with nil license_key_type" do
          populator.should_receive(:get_available_keys).once.with(quantity, nil).and_call_original
          populator.populate(inventory_unit, quantity)
        end
      end

      context "variant has multiple license key types" do
        let(:license_key_type_1) { build_stubbed :license_key_type }
        let(:license_key_type_2) { build_stubbed :license_key_type }
        let(:variant) { build_stubbed :variant, license_key_types: [license_key_type_1, license_key_type_2] }

        it_behaves_like "license key populator"

        it "calls get_available_keys twice" do
          populator.should_receive(:get_available_keys).twice.and_call_original
          populator.populate(inventory_unit, quantity)
        end

        it "calls get_available_keys once for each license key type" do
          populator.should_receive(:get_available_keys).once.with(quantity, license_key_type_1).and_call_original
          populator.should_receive(:get_available_keys).once.with(quantity, license_key_type_2).and_call_original
          populator.populate(inventory_unit, quantity)
        end
      end
    end
  end
end
