require 'rails_helper'

RSpec.describe SchoolGroups::MeterReport do

  let(:school_group) { create :school_group, name: 'A Group' }
  let(:all_meters) { false }
  subject(:meter_report) { SchoolGroups::MeterReport.new(school_group, all_meters: all_meters) }

  let!(:active_meter) { create :gas_meter, active: true, school: create(:school, school_group: school_group) }
  let!(:inactive_meter) { create :gas_meter, active: false, school: create(:school, school_group: school_group) }

  let(:header) { 'School,Supply,Number,Meter,Data source,Active,First validated reading,Last validated reading,Large gaps (last 2 years),Modified readings (last 2 years),Zero reading days,Admin meter status' }

  describe "#csv_filename" do
    it { expect(meter_report.csv_filename).to eq("a-group-meter-report.csv") }
  end

  describe "#csv" do
    subject(:csv) { meter_report.csv }

    context "only active meters" do
      let(:all_meters) { false }
      it { expect(csv.lines.first.chomp).to eq(header) }
      it { expect(csv.lines.count).to eq(2) }
      it { expect(csv.lines.second).to include(active_meter.school_name) }
    end

    context "all meters" do
      let(:all_meters) { true }

      it { expect(csv.lines.first.chomp).to eq(header) }
      it { expect(csv.lines.count).to eq(3) }
      it { expect(csv).to include(active_meter.school_name) }
      it { expect(csv).to include(inactive_meter.school_name) }
    end

  end
end
