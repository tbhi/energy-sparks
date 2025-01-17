require 'rails_helper'

describe Schools::SchoolRegenerationService, type: :service do
  let(:school)            { create(:school) }

  let(:logger)            { double(Rails.logger) }

  #this will create an empty meter collection as the school has no data
  let(:meter_collection)  { Amr::AnalyticsMeterCollectionFactory.new(school).validated }

  subject(:service)       { Schools::SchoolRegenerationService.new(school: school, logger: logger) }

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe '#perform' do
    context 'when there are no errors' do
      it 'calls validate, update cache and regenerate metrics ' do
        expect_any_instance_of(Amr::ValidateAndPersistReadingsService).to receive(:perform).and_return(meter_collection)
        expect_any_instance_of(Amr::AnalyticsMeterCollectionFactory).not_to receive(:validated)
        expect_any_instance_of(AggregateDataService).to receive(:aggregate_heat_and_electricity_meters)
        expect_any_instance_of(AggregateSchoolService).to receive(:cache)
        expect_any_instance_of(AggregateSchoolService).not_to receive(:invalidate_cache)
        expect_any_instance_of(Schools::SchoolMetricsGeneratorService).to receive(:perform)
        expect(service.perform).to be true
      end
    end

    context 'when validation fails' do
      before do
        allow_any_instance_of(Amr::ValidateAndPersistReadingsService).to receive(:perform).and_raise
      end

      it 'tries to fallback and continue with the other steps' do
        expect_any_instance_of(Amr::AnalyticsMeterCollectionFactory).to receive(:validated).and_return(meter_collection)
        expect_any_instance_of(AggregateDataService).to receive(:aggregate_heat_and_electricity_meters)
        expect_any_instance_of(AggregateSchoolService).to receive(:cache)
        expect_any_instance_of(AggregateSchoolService).not_to receive(:invalidate_cache)
        expect_any_instance_of(Schools::SchoolMetricsGeneratorService).to receive(:perform)
        expect(service.perform).to be true
      end
    end

    context 'when aggregation step fails' do
      it 'invalidates cache and does not regenerate metrics' do
        expect_any_instance_of(Amr::ValidateAndPersistReadingsService).to receive(:perform).and_return(meter_collection)
        expect_any_instance_of(Amr::AnalyticsMeterCollectionFactory).not_to receive(:validated)
        expect_any_instance_of(AggregateDataService).to receive(:aggregate_heat_and_electricity_meters).and_raise
        expect_any_instance_of(AggregateSchoolService).not_to receive(:cache)
        expect_any_instance_of(AggregateSchoolService).to receive(:invalidate_cache)
        expect_any_instance_of(Schools::SchoolMetricsGeneratorService).not_to receive(:perform)
        expect(service.perform).to be false
      end
    end
  end
end
