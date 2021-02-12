require 'rails_helper'

RSpec.describe Schools::MetersController, type: :controller do

  let(:valid_attributes) {
    {
      mpan_mprn: 2199989617206,
      name: "Test meter",
      meter_serial_number: "123",
      meter_type: :electricity,
      dcc_meter: "0",
      consent_granted: "0"
    }
  }
  let(:invalid_attributes) {
    { mpan_mprn: nil }
  }

  let!(:school)           { create(:school) }

  context "as an admin user" do
    before(:each) do
      sign_in_user(:admin)
    end

    describe "POST #create" do
      context "with valid parameters" do
        it "creates a new Meter" do
          expect {
            post :create, params: { school_id: school.id, meter: valid_attributes }
          }.to change(Meter, :count).by(1)
        end
      end

      context "with invalid parameters" do
        it "assigns a newly created but unsaved meter as @meter" do
          post :create, params: { school_id: school.id, meter: invalid_attributes }
          expect(assigns(:meter)).to be_a_new(Meter)
        end

        it "re-renders the meters index" do
          post :create, params: { school_id: school.id, meter: invalid_attributes }
          expect(response).to render_template("index")
        end

      end

      context "with DCC meters" do
        let(:dcc_meter_attributes) {
          {
            mpan_mprn: 2199989617206,
            name: "Test meter",
            meter_serial_number: "123",
            meter_type: :electricity,
            dcc_meter: "1",
            consent_granted: "1"
          }
        }
        it "allows registered DCC meters to be added" do
          allow_any_instance_of(MeterManagement).to receive(:valid_dcc_meter?).and_return(true)
          expect {
            post :create, params: { school_id: school.id, meter: dcc_meter_attributes }
          }.to change(Meter, :count).by(1)
        end

        it "does not allow unregistered DCC meters to be added" do
          allow_any_instance_of(MeterManagement).to receive(:valid_dcc_meter?).and_return(false)
          expect {
            post :create, params: { school_id: school.id, meter: dcc_meter_attributes }
          }.not_to change(Meter, :count)
        end
      end
    end

    describe "PUT #update" do
      context "with valid attributes" do
        let(:new_attributes) {
          {
            mpan_mprn: 2199989617206,
            name: "Test meter",
            meter_serial_number: "123",
            meter_type: :electricity,
            dcc_meter: "0",
            consent_granted: "0"
          }
        }
        it "updates meter" do
          meter = create :electricity_meter, school: school
          put :update, params: { school_id: school.id, id: meter.to_param, meter: new_attributes }
          meter.reload
          expect(meter.name).to eq new_attributes[:name]
        end
      end

      context "when editing DCC values" do
        let(:new_attributes) {
          {
            mpan_mprn: 2199989617206,
            name: "New name",
            meter_serial_number: "123",
            meter_type: :electricity,
            dcc_meter: "1",
            consent_granted: "1"
          }
        }
        let(:meter)  { create :electricity_meter, name: "Original name", school: school, dcc_meter: false }

        it "allows DCC registered meters to be activated" do
          expect_any_instance_of(MeterManagement).to receive(:valid_dcc_meter?).and_return(true)
          put :update, params: { school_id: school.id, id: meter.id, meter: new_attributes }
          meter.reload
          expect(meter.dcc_meter?).to eq true
        end

        it "does not allow unregistered DCC meters to be activated" do
          expect_any_instance_of(MeterManagement).to receive(:valid_dcc_meter?).and_return(false)
          original_name = meter.name
          put :update, params: { school_id: school.id, id: meter.id, meter: new_attributes }
          meter.reload
          expect(meter.name).to eq original_name
          expect(meter.dcc_meter?).to eq false
        end

        it "validates new meter mpan, not the old one, and does not update meter" do
          non_dcc_mpan = 1234561234561
          expect_any_instance_of(MeterReadingsFeeds::N3rgyData).to receive(:status).with(non_dcc_mpan).and_return(false)
          put :update, params: { school_id: school.id, id: meter.id, meter: new_attributes.merge(mpan_mprn: non_dcc_mpan) }
          meter.reload
          expect(meter.dcc_meter?).to eq false
        end
      end
    end

  end

end
