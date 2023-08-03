require 'dashboard'

module Amr
  class N3rgyTariffsUpserter
    def initialize(meter:, tariffs:, import_log:)
      @meter = meter
      @tariffs = tariffs
      @import_log = import_log
      @import_log_error_messages = []
    end

    def perform
      return if @tariffs.empty?
      Rails.logger.info "Upserting #{kwh_tariffs.count} tariff_prices and #{standing_charges.count} tariff_standing_charges for #{@meter.mpan_mprn} at #{@meter.school.name}"

      prices_array = prices_array(kwh_tariffs)
      standing_charges_array = standing_charges_array(standing_charges)

      if @import_log_error_messages.present?
        @import_log.error_messages = "Error downloading tariffs: " + @import_log_error_messages.to_sentence
        @import_log.save!
      end

      TariffUpserter.new(prices_array, standing_charges_array, @import_log).perform
      Rails.logger.info "Upserted #{@import_log.prices_updated} prices and #{@import_log.standing_charges_updated} standing charges for #{@meter.mpan_mprn} at #{@meter.school.name}"
      Rails.logger.info "Inserted #{@import_log.prices_imported} prices and #{@import_log.standing_charges_imported} standing charges for #{@meter.mpan_mprn} at #{@meter.school.name}"
    end

    private

    def kwh_tariffs
      @tariffs[:kwh_tariffs]
    end

    def standing_charges
      @tariffs[:standing_charges]
    end

    def prices_array(tariff_prices_hash)
      last_prices = TariffPrice.where(meter_id: @meter.id).order(tariff_date: :asc).last&.prices

      tariff_prices_hash.map do |tariff_date, prices|
        if prices.all? { |price| price.is_a?(Numeric) } && prices.sum == 0.0
          @import_log_error_messages << "prices returned from n3rgy for #{tariff_date} are zero"

          next
        end

        next if last_prices && (last_prices == prices)

        {
          meter_id: @meter.id,
          tariff_date: tariff_date,
          prices: prices
        }
      end&.compact
    end

    def standing_charges_array(standing_charges_hash)
      standing_charges_hash.map do |start_date, value|
        if value <= 0.0
          @import_log_error_messages << "standing charges returned from n3rgy for #{start_date} are zero"

          next
        end

        {
          meter_id: @meter.id,
          start_date: start_date,
          value: value
        }
      end&.compact
    end
  end
end
