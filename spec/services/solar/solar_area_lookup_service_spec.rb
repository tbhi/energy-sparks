require 'rails_helper'

describe Solar::SolarAreaLookupService, type: :service do

  #location is somewhere in north america
  let!(:solar_area)      { create(:solar_pv_tuos_area, gsp_id: 1, latitude: 42.143042, longitude: -106.352703) }

  #near bath
  let!(:bath_area)       { create(:solar_pv_tuos_area, gsp_id: 199, gsp_name: "MELK_1", latitude: 51.344996, longitude: -2.008303, active: false) }
  #in the Highlands
  let!(:highlands_area) { create(:solar_pv_tuos_area, gsp_id: 18, gsp_name: "BEAU_P|ORRI_P", latitude: 57.51208, longitude: -4.560742, active: false) }

  let(:school_onboarding) { create(:school_onboarding, solar_pv_tuos_area: solar_area)}
  let(:school)            { create(:school) }

  let(:service)         { Solar::SolarAreaLookupService.new(school, school_onboarding) }

  context 'with feature flag off' do
    it 'returns the area for the group' do
      ClimateControl.modify FEATURE_FLAG_AUTO_ASSIGN_SOLAR_AREA: 'false' do
        expect(service.lookup).to eq solar_area
        expect(school.solar_pv_tuos_area).to be_nil
      end
    end

    it 'assigns the area from the group' do
      ClimateControl.modify FEATURE_FLAG_AUTO_ASSIGN_SOLAR_AREA: 'false' do
        expect(service.assign).to eq solar_area
        expect(school.solar_pv_tuos_area).to eq solar_area
      end
    end
  end

  context 'with feature flag on' do
    it 'finds nearest area' do
      ClimateControl.modify FEATURE_FLAG_AUTO_ASSIGN_SOLAR_AREA: 'true' do
        expect(service.lookup).to eq bath_area
        expect(school.solar_pv_tuos_area).to be_nil
      end
    end
    it 'assigns the nearest area' do
      ClimateControl.modify FEATURE_FLAG_AUTO_ASSIGN_SOLAR_AREA: 'true' do
        expect(service.assign).to eq bath_area
        expect(school.solar_pv_tuos_area).to eq bath_area
        bath_area.reload
        expect(bath_area.active).to eq true
      end
    end
  end

end