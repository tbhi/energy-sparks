module SchoolProgress
  extend ActiveSupport::Concern

private

  def prompt_for_target?
    EnergySparks::FeatureFlags.active?(:school_targets) && !@school.has_target? && Targets::SchoolTargetService.new(@school).enough_data?
  end

  def calculate_current_progress
    @electricity_progress = progress_service.electricity_progress
    @gas_progress = progress_service.gas_progress
    @storage_heater_progress = progress_service.storage_heater_progress
  end

  def setup_management_table
    @overview_table = progress_service.setup_management_table
  end

  def progress_service
    @progress_service ||= Targets::ProgressService.new(@school, aggregate_school)
  end
end