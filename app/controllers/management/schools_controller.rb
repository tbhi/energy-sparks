module Management
  class SchoolsController < ApplicationController
    load_and_authorize_resource

    include SchoolAggregation
    include DashboardEnergyCharts
    include DashboardAlerts
    include DashboardTimeline

    before_action :check_aggregated_school_in_cache

    def show
      authorize! :show_management_dash, @school
      @charts = setup_charts(@school.configuration)
      @dashboard_alerts = setup_alerts(@school.latest_dashboard_alerts.management_dashboard, :management_dashboard_title)
      @observations = setup_timeline(@school.observations)
      @management_priorities = setup_priorities
      @overview_charts = setup_energy_overview_charts
    end


    private

    def setup_priorities
      management_priorities_limit = site_settings.management_priorities_dashboard_limit
      all_priorities = @school.latest_management_priorities
      @show_more_management_priorities = all_priorities.count > management_priorities_limit
      all_priorities.by_priority.limit(management_priorities_limit).map do |priority|
        TemplateInterpolation.new(
          priority.content_version,
          with_objects: { find_out_more: priority.find_out_more },
          proxy: [:colour]
        ).interpolate(
          :management_priorities_title,
          with: priority.alert.template_variables
        )
      end
    end

    def setup_energy_overview_charts
      return {} unless @school.configuration
      {
        electricity: [:analysis_charts, :electricity_detail, :group_by_week_electricity],
        gas: [:analysis_charts, :gas_detail, :group_by_week_gas],
        storage_heater: [:analysis_charts, :storage_heaters, :storage_heater_group_by_week],
        solar: [:analysis_charts, :solar_pv, :solar_pv_group_by_month]
      }.select {|_energy, chart_config| @school.configuration.can_show_analysis_chart?(*chart_config)}
    end
  end
end
