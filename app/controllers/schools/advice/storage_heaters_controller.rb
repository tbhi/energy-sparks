module Schools
  module Advice
    class StorageHeatersController < AdviceBaseController
      before_action :set_seasonal_analysis, only: [:insights, :analysis]
      before_action :set_annual_usage_breakdown, only: [:insights, :analysis]
      before_action :set_usage_categories, only: [:insights, :analysis]
      before_action :set_heating_thermostatic_analysis, only: [:insights, :analysis]

      def insights
      end

      def analysis
        @analysis_dates = analysis_dates
      end

      private

      def set_heating_thermostatic_analysis
        @heating_thermostatic_analysis = build_heating_thermostatic_analysis
      end

      def build_heating_thermostatic_analysis
        ::Heating::HeatingThermostaticAnalysisService.new(
          meter_collection: aggregate_school,
          fuel_type: :storage_heater
        ).create_model
      end

      def set_annual_usage_breakdown
        @annual_usage_breakdown = build_annual_usage_breakdown
      end

      def build_annual_usage_breakdown
        ::Usage::AnnualUsageBreakdownService.new(
          meter_collection: aggregate_school,
          fuel_type: :storage_heater
        ).usage_breakdown
      end

      def set_seasonal_analysis
        @seasonal_analysis = build_seasonal_analysis
      end

      def build_seasonal_analysis
        ::Heating::SeasonalControlAnalysisService.new(meter_collection: aggregate_school, fuel_type: :storage_heater).seasonal_analysis
      end

      def set_insights_next_steps
        @advice_page_insights_next_steps = t("advice_pages.#{advice_page_key}.insights.next_steps_html").html_safe
      end

      def advice_page_key
        :storage_heaters
      end

      def set_usage_categories
        @usage_categories = [:holiday, :weekend, :school_day_open, :school_day_closed]
        @usage_categories += [:community] if @school.school_times.community_use.any?
        @usage_categories
      end
    end
  end
end
