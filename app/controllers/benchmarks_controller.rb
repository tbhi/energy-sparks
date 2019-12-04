require 'dashboard'

class BenchmarksController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :page_groups, only: [:index, :show_all]
  before_action :filter_lists, only: [:show, :show_all]
  before_action :benchmark_results, only: [:show, :show_all]
  before_action :set_up_content_and_errors, only: [:show, :show_all]

  def index
  end

  def show
    respond_to do |format|
      format.html do
        @page = params[:benchmark_type].to_sym
        @page_groups = [{ name: '', benchmarks: { @page => @page } }]

        @form_path = benchmark_path
        @content_hash[@page] = filter_content(content_for_page(@page, @errors))
      end
      format.yaml { send_data YAML.dump(@benchmark_results), filename: "benchmark_results_data.yaml" }
    end
  end

  def show_all
    @title = 'All benchmark results'
    @form_path = all_benchmarks_path

    @page_groups.each do |heading_hash|
      heading_hash[:benchmarks].each do |page, _title|
        @content_hash[page] = filter_content(content_for_page(page, @errors))
      end
    end

    render :show
  end

private

  def page_groups
    # Can't pass a hash as a parameter to the existing analytics method as it currently accepts normal parameters
    # def self.structured_pages(_user_type_hash, filter_out = nil)

    # user_type_hash = if current_user
    #                    { user_role: current_user.role.to_sym, staff_role: current_user.staff_role_as_symbol }
    #                  else
    #                    { user_role: :guest, staff_role: nil }
    #                  end

    # @page_groups = content_manager.structured_pages(user_type_hash)
    @page_groups = content_manager.structured_pages
  end

  def filter_lists
    @school_groups = SchoolGroup.all
    @fuel_types = [:gas, :electricity, :solar_pv, :storage_heaters]
  end

  def benchmark_results
    @school_group_ids = params.dig(:benchmark, :school_group_ids) || []
    @fuel_type = params.dig(:benchmark, :fuel_type)

    schools = SchoolFilter.new(school_group_ids: @school_group_ids, fuel_type: @fuel_type).filter
    @benchmark_results = Alerts::CollateBenchmarkData.new.perform(schools)
  end

  def set_up_content_and_errors
    @content_hash = {}
    @errors = []
  end

  def content_manager(date = Time.zone.today)
    Benchmarking::BenchmarkContentManager.new(date)
  end

  def content_for_page(page, errors = [])
    content_manager.content(@benchmark_results, page)
    # rubocop:disable Lint/RescueException
  rescue Exception => e
    # rubocop:enable Lint/RescueException
    error_message = "Exception: #{page}: #{e.class} #{e.message} #{e.backtrace.join("\n")}"
    errors << error_message
    {}
  end

  def filter_content(all_content)
    all_content.select { |content| content_select?(content) }
  end

  def content_select?(content)
    return false unless content.present?

    [:chart, :html, :table_composite, :title].include?(content[:type]) && content[:content].present?
  end
end
