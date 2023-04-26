module Admin
  module SchoolGroups
    class MeterReportsController < AdminController
      include ApplicationHelper
      load_and_authorize_resource :school_group

      def show
        respond_to do |format|
          format.html { @meters = meter_report.meters }
          format.csv { send_data meter_report.csv, filename: meter_report.csv_filename }
        end
      end

      def deliver
        meter_report = ::SchoolGroups::MeterReport.new(@school_group)
        AdminMailer.with(to: current_user.email, meter_report: meter_report).school_group_meters_report.deliver


        #SchoolGroupMeterReportJob.perform_later(to: current_user.email, school_group: @school_group)
        redirect_to admin_school_group_path(@school_group), notice: "Report requested to be sent to #{current_user.email}"
      end

      private

      def meter_report
        @meter_report ||= ::SchoolGroups::MeterReport.new(@school_group, full_detail: false, all_meters: !!params[:all_meters])
      end
    end
  end
end
