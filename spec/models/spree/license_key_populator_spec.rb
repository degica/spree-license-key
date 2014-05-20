require 'spec_helper'
require 'timecop'

describe Spree::LicenseKeyPopulator do
  describe '.populate' do
    let(:inventory_unit) { build_stubbed :inventory_unit, variant: variant }
    let(:variant) { nil }
    let(:quantity) { 2 }

    describe ".get_available_keys" do
      it "raises NotImplementedError" do
        expect { Spree::LicenseKeyPopulator.get_available_keys(inventory_unit, quantity) }.to raise_error(NotImplementedError)
      end
    end

    describe ".populate" do
      before { quantity.times { create :license_key } }
      let(:populator_class) do
        Class.new(Spree::LicenseKeyPopulator) do
          # Minimal populator function, returns false if there are not enough keys.
          def self.get_available_keys(inventory_unit, quantity, license_key_type=nil)
            quantity <= Spree::LicenseKey.count ?  Spree::LicenseKey.scoped : false
          end
        end
      end

      shared_examples_for "license key populator" do
        it "assigns inventory unit id to each license key" do
          keys = populator_class.populate(inventory_unit, quantity)
          keys.each { |key| key.inventory_unit_id.should == inventory_unit.id }
        end

        it "updates timestamps on license keys when they are assigned" do
          t = Date.today + 5
          keys = Timecop.freeze(t) { populator_class.populate(inventory_unit, quantity) }
          keys.each { |key| key.updated_at.should == t }
        end

        it "raises error for insufficient keys if none are available" do
          expect { populator_class.populate(inventory_unit, quantity + 1) }.to raise_error(Spree::LicenseKeyPopulator::InsufficientLicenseKeys)
        end
      end

      context "variant has no license key types" do
        let(:variant) { build_stubbed :variant }

        it_behaves_like "license key populator"

        it "calls get_available_keys once with nil license_key_type" do
          populator_class.should_receive(:get_available_keys).once.with(inventory_unit, quantity, nil).and_call_original
          populator_class.populate(inventory_unit, quantity)
        end
      end

      context "variant has multiple license key types" do
        let(:license_key_type_1) { build_stubbed :license_key_type }
        let(:license_key_type_2) { build_stubbed :license_key_type }
        let(:variant) { build_stubbed :variant, license_key_types: [license_key_type_1, license_key_type_2] }

        it_behaves_like "license key populator"

        it "calls get_available_keys twice" do
          populator_class.should_receive(:get_available_keys).twice.and_call_original
          populator_class.populate(inventory_unit, quantity)
        end

        it "calls get_available_keys once for each license key type" do
          populator_class.should_receive(:get_available_keys).once.with(inventory_unit, quantity, license_key_type_1).and_call_original
          populator_class.should_receive(:get_available_keys).once.with(inventory_unit, quantity, license_key_type_2).and_call_original
          populator_class.populate(inventory_unit, quantity)
        end
      end
    end
  end
end
