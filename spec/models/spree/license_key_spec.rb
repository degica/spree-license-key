require 'spec_helper'

describe Spree::LicenseKey do
  let(:inventory_unit) { create :spree_inventory_unit }
  let!(:available_license_key) { create :license_key }
  let!(:used_license_key) { create :license_key, inventory_unit: inventory_unit }

  describe '.available' do
    it 'returns license keys which do not have inventory units' do
      Spree::LicenseKey.available.all.should == [ available_license_key ]
    end

    it 'does not return void license keys' do
      create :license_key, void: true
      Spree::LicenseKey.available.all.should == [ available_license_key ]
    end
  end

  describe '.used' do
    it 'returns license keys which have inventory units' do
      Spree::LicenseKey.used.all.should == [ used_license_key ]
    end

    it 'returns license keys which are void' do
      void_license_key = create :license_key, void: true
      Spree::LicenseKey.used.should include void_license_key
    end
  end
end
