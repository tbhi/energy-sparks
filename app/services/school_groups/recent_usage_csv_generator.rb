module SchoolGroups
  class RecentUsageCsvGenerator
    def initialize(school_group:, metric: 'change')
      raise unless %w[change usage cost co2].include?(metric)
      @school_group = school_group
      @metric = metric + '_text'
    end

    def export
      CSV.generate(headers: true) do |csv|
        csv << headers
        @school_group.schools.visible.order(:name).each do |school|
          recent_usage = school&.recent_usage
          row = []
          row << school.name
          fuel_types.each { |fuel_type| row += columns_for(fuel_type, recent_usage) }
          csv << row
        end
      end
    end

    private

    def columns_for(fuel_type, recent_usage)
      columns = []
      columns << (recent_usage&.send(fuel_type)&.week&.has_data ? recent_usage&.send(fuel_type)&.week&.send(@metric) : '-')
      columns << (recent_usage&.send(fuel_type)&.year&.has_data ? recent_usage&.send(fuel_type)&.year&.send(@metric) : '-')
      columns
    end

    def fuel_types
      # Only include electricity, gas and storage heaters fuel types (e.g. exclude solar pv)
      @fuel_types ||= @school_group.fuel_types & [:electricity, :gas, :storage_heaters]
    end

    def headers
      header_row = []
      header_row << I18n.t('common.school')
      fuel_types.each { |fuel_type| header_row += header_columns_for(fuel_type) }
      header_row
    end

    def header_columns_for(fuel_type)
      columns = []
      columns << I18n.t("common.#{fuel_type}") + ' ' + I18n.t('common.labels.last_week')
      columns << I18n.t("common.#{fuel_type}") + ' ' + I18n.t('common.labels.last_year')
      columns
    end
  end
end
