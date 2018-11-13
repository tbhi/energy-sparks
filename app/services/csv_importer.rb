require 'upsert'
require 'upsert/active_record_upsert'
require 'upsert/connection/postgresql'
require 'upsert/connection/PG_Connection'
require 'upsert/merge_function/PG_Connection'
require 'upsert/column_definition/postgresql'
require 'csv'

class CsvImporter
  attr_reader :inserted_record_count

  def initialize(config, file_name)
    @file_name = file_name
    @config = config
    @map_of_fields_to_indexes = @config.map_of_fields_to_indexes
    @range_of_readings = @config.range_of_readings
    @inserted_record_count = 0
    @existing_records = AmrDataFeedReading.count
    @meter_id_hash = Meter.all.map { |m| [m.meter_no.to_s, m.id]}.to_h
  end

  def parse
    Rails.logger.info "Loading: #{@config.local_bucket_path}/#{@file_name}"
    amr_data_feed_import_log = AmrDataFeedImportLog.create(amr_data_feed_config_id: @config.id, file_name: @file_name, import_time: DateTime.now.utc)

    Upsert.batch(AmrDataFeedReading.connection, AmrDataFeedReading.table_name) do |upsert|
      begin
        CSV.foreach("#{@config.local_bucket_path}/#{@file_name}", col_sep: @config.column_separator, row_sep: :auto, headers: @config.expect_headers) do |row|
          create_record(upsert, row, amr_data_feed_import_log.id)
        end
      rescue CSV::MalformedCSVError
        Rails.logger.error "Malformed CSV"
      end
    end
    @inserted_record_count = AmrDataFeedReading.count - @existing_records
    amr_data_feed_import_log.update(records_imported: @inserted_record_count)
    @inserted_record_count
  end

private

  def invalid_row?(row)
    row.empty? || row[@map_of_fields_to_indexes[:mpan_mprn_index]].blank? || row[@range_of_readings].compact.nil?
  end

  def create_record(upsert, row, amr_data_feed_import_log_id)
    return if invalid_row?(row)
    readings = row[@range_of_readings]

    mpan_mprn = row[@map_of_fields_to_indexes[:mpan_mprn_index]]
    reading_date_string = row[@map_of_fields_to_indexes[:reading_date_index]]

    meter_id = @meter_id_hash[mpan_mprn]

    # This determines which row to select, values get updated for this particular row
    unique_record_selector = { mpan_mprn: mpan_mprn, reading_date: reading_date_string }

    upsert.row(unique_record_selector,
      amr_data_feed_config_id: @config.id,
      meter_id: meter_id,
      mpan_mprn: mpan_mprn,
      reading_date: reading_date_string,
      postcode: row[@map_of_fields_to_indexes[:postcode_index]],
      units: row[@map_of_fields_to_indexes[:units_index]],
      description: row[@map_of_fields_to_indexes[:description_index]],
      meter_serial_number: row[@map_of_fields_to_indexes[:meter_serial_number_index]],
      provider_record_id: row[@map_of_fields_to_indexes[:provider_record_id_index]],
      readings: readings,
      amr_data_feed_import_log_id: amr_data_feed_import_log_id,
      created_at: DateTime.now.utc,
      updated_at: DateTime.now.utc
    )
  end
end
