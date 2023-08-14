# == Schema Information
#
# Table name: energy_tariffs
#
#  ccl                :boolean          default(FALSE)
#  created_at         :datetime         not null
#  created_by_id      :bigint(8)
#  enabled            :boolean          default(FALSE)
#  end_date           :date
#  id                 :bigint(8)        not null, primary key
#  meter_type         :integer          default("electricity"), not null
#  name               :text             not null
#  source             :integer          default("manual"), not null
#  start_date         :date
#  tariff_holder_id   :bigint(8)
#  tariff_holder_type :string
#  tariff_type        :integer          default("flat_rate"), not null
#  tnuos              :boolean          default(FALSE)
#  updated_at         :datetime         not null
#  updated_by_id      :bigint(8)
#  vat_rate           :float
#
# Indexes
#
#  index_energy_tariffs_on_created_by_id                            (created_by_id)
#  index_energy_tariffs_on_tariff_holder_type_and_tariff_holder_id  (tariff_holder_type,tariff_holder_id)
#  index_energy_tariffs_on_updated_by_id                            (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class EnergyTariff < ApplicationRecord
  belongs_to :tariff_holder, polymorphic: true

  #Declaring associations allows us to use .joins(:school) or .joins(:school_group)
  belongs_to :school, -> { where(energy_tariffs: { tariff_holder_type: 'School' }) }, foreign_key: 'tariff_holder_id', optional: true
  belongs_to :school_group, -> { where(energy_tariffs: { tariff_holder_type: 'SchoolGroup' }) }, foreign_key: 'tariff_holder_id', optional: true

  delegated_type :tariff_holder, types: %w[SiteSettings School SchoolGroup]

  has_many :energy_tariff_prices, inverse_of: :energy_tariff, dependent: :destroy
  has_many :energy_tariff_charges, inverse_of: :energy_tariff, dependent: :destroy

  #only populated if tariff_holder is school
  has_and_belongs_to_many :meters, inverse_of: :energy_tariffs

  belongs_to :created_by, optional: true, class_name: 'User'
  belongs_to :updated_by, optional: true, class_name: 'User'

  enum source: [:manually_entered, :dcc]
  enum meter_type: [:electricity, :gas, :solar_pv, :exported_solar_pv]
  enum tariff_type: [:flat_rate, :differential]

  validates :name, presence: true
  validate :start_and_end_date_are_not_both_blank

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  scope :has_prices, -> { where(id: EnergyTariffPrice.select(:energy_tariff_id)) }
  scope :has_charges, -> { where(id: EnergyTariffCharge.select(:energy_tariff_id)) }
  scope :complete, -> { has_prices.or(has_charges) }

  scope :by_name, -> { order(name: :asc) }
  scope :by_start_date, -> { order(start_date: :asc) }

  scope :count_by_school_group, -> { enabled.joins(:school_group).group(:slug).count(:id) }

  scope :for_schools_in_group, ->(school_group, source = :manually_entered) {
    enabled.where(source: source).joins(:school).where({ schools: { school_group: school_group } })
  }
  scope :count_schools_with_tariff_by_group, ->(school_group, source = :manually_entered) {
    for_schools_in_group(school_group, source).select(:tariff_holder_id).distinct.count
  }

  def meter_attribute
    MeterAttribute.new(attribute_type: :accounting_tariff_generic, input_data: to_hash)
  end

  def to_hash
    rates = rates_attrs
    {
      start_date: start_date ? start_date.to_s(:es_compact) : Date.new(2000, 1, 1).to_s(:es_compact),
      end_date: end_date ? end_date.to_s(:es_compact) : Date.new(2050, 1, 1).to_s(:es_compact),
      source: source.to_sym,
      name: name,
      type: flat_rate? ? :flat : :differential,
      sub_type: '',
      rates: rates,
      vat: vat_rate.nil? ? nil : "#{vat_rate}%",
      climate_change_levy: ccl,
      asc_limit_kw: (value_for_charge(:asc_limit_kw) if rates_has_availability_charge?(rates)),
      tariff_holder: tariff_holder_symbol,
      created_at: created_at.to_datetime
    }.compact
  end

  def value_for_charge(type)
    if (charge = energy_tariff_charges.for_type(type).first)
      charge.value.to_s
    end
  end

  def site_settings_tariff_holder?
    tariff_holder_symbol == :site_settings
  end

  def tariff_holder_route
    if tariff_holder_type == 'SiteSettings'
      [:admin, :settings]
    else
      [tariff_holder]
    end
  end

  private

  def start_and_end_date_are_not_both_blank
    return unless tariff_holder_type == 'SchoolGroup'
    return if start_date.present? || end_date.present?

    errors.add(:start_date, I18n.t('schools.user_tariffs.form.errors.dates.start_and_end_date_can_not_both_be_empty'))
    errors.add(:end_date, I18n.t('schools.user_tariffs.form.errors.dates.start_and_end_date_can_not_both_be_empty'))
  end

  def tariff_holder_symbol
    meters.any? ? :meter : tariff_holder_type&.underscore&.to_sym
  end

  def rates_attrs
    attrs = {}
    if flat_rate?
      if (first_price = energy_tariff_prices.first)
        attrs[:flat_rate] = { rate: first_price.value.to_s, per: first_price.units.to_s }
      end
    else
      energy_tariff_prices.each_with_index do |price, idx|
        attrs["rate#{idx}".to_sym] = { rate: price.value.to_s, per: price.units.to_s, from: hour_minutes(price.start_time), to: hour_minutes(price.end_time.advance(minutes: -30)) }
      end
    end
    energy_tariff_charges.select { |c| c.units.present? }.each do |charge|
      charge_value = { rate: charge.value.to_s, per: charge.units.to_s }
      charge_type = charge.charge_type.to_sym
      #only add these charges if we also have an asc limit
      if charge.is_type?([:agreed_availability_charge, :excess_availability_charge])
        attrs[charge_type] = charge_value if value_for_charge(:asc_limit_kw).present?
      else
        attrs[charge_type] = charge_value
      end
    end
    energy_tariff_charges.select { |c| c.is_type?([:duos_red, :duos_amber, :duos_green]) }.each do |charge|
      attrs[charge.charge_type.to_sym] = charge.value.to_s
    end
    attrs[:tnuos] = tnuos
    attrs
  end

  def rates_has_availability_charge?(rates)
    rates.key?(:agreed_availability_charge) || rates.key?(:excess_availability_charge)
  end

  def hour_minutes(time)
    hm = time.to_s(:time).split(':')
    {
      hour: hm.first,
      minutes: hm.last
    }
  end
end