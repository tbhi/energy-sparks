module Admin
  class AmrDataFeedReadingsController < AdminController
    def create
      amr_upload_reading = AmrUploadedReading.find(params[:amr_uploaded_reading_id])

      amr_data_feed_import_log = AmrDataFeedImportLog.create(
        amr_data_feed_config_id: amr_upload_reading.amr_data_feed_config_id,
        file_name: amr_upload_reading.file_name,
        import_time: DateTime.now.utc
                                                            )

      @upserted_record_count = Amr::DataFeedUpserter.new(amr_upload_reading.reading_data, amr_data_feed_import_log.id).perform

      redirect_to admin_amr_data_feed_config_path(amr_upload_reading.amr_data_feed_config_id), notice: "We have inserted #{@upserted_record_count} records"
    end
  end
end
