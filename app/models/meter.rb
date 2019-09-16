# == Schema Information
#
# Table name: meters
#
#  active                          :boolean          default(TRUE)
#  created_at                      :datetime         not null
#  id                              :bigint(8)        not null, primary key
#  low_carbon_hub_installations_id :bigint(8)
#  meter_serial_number             :text
#  meter_type                      :integer
#  mpan_mprn                       :bigint(8)
#  name                            :string
#  school_id                       :bigint(8)        not null
#  updated_at                      :datetime         not null
#
# Indexes
#
#  index_meters_on_low_carbon_hub_installations_id  (low_carbon_hub_installations_id)
#  index_meters_on_meter_type                       (meter_type)
#  index_meters_on_mpan_mprn                        (mpan_mprn) UNIQUE
#  index_meters_on_school_id                        (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (low_carbon_hub_installations_id => low_carbon_hub_installations.id) ON DELETE => cascade
#  fk_rails_...  (school_id => schools.id)
#

class Meter < ApplicationRecord
  belongs_to :school, inverse_of: :meters
  belongs_to :low_carbon_hub_installation, optional: true

  has_many :amr_data_feed_readings,     inverse_of: :meter, dependent: :nullify
  has_many :amr_validated_readings,     inverse_of: :meter, dependent: :destroy

  scope :active,   -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :no_amr_validated_readings, -> { left_outer_joins(:amr_validated_readings).where(amr_validated_readings: { meter_id: nil }) }

  enum meter_type: [:electricity, :gas, :solar_pv, :exported_solar_pv]

  delegate :area_name, to: :school

  attr_accessor :pseudo_mpan

  validates_presence_of :school, :mpan_mprn, :meter_type
  validates_uniqueness_of :mpan_mprn

  validates_format_of :mpan_mprn, with: /\A[1-3]\d{12}\Z/, if: :traditional_mpan?, message: 'for electricity meters should be a 13 digit number'
  validates_format_of :mpan_mprn, with: /\A[6,7,9]\d{13}\Z/, if: :pseudo_mpan?, message: 'for electricity meters should be a 13 digit number'
  validates_format_of :mpan_mprn, with: /\A\d{1,10}\Z/, if: :gas?, message: 'for gas meters should be a 1-10 digit number'

  def fuel_type
    meter_type.to_sym
  end

  def first_validated_reading
    amr_validated_readings.minimum(:reading_date)
  end

  def last_validated_reading
    amr_validated_readings.maximum(:reading_date)
  end

  def display_name
    name.present? ? "#{mpan_mprn} (#{name})" : display_meter_mpan_mprn
  end

  def display_meter_mpan_mprn
    mpan_mprn.present? ? mpan_mprn : meter_type.to_s
  end

  def meter_attributes(meter_attributes = MeterAttributes)
    meter_attributes.for(mpan_mprn, area_name, meter_type.to_sym)
  end

  def attributes(attribute_type)
    meter_attributes[attribute_type]
  end

  def solar_pv?
    ! solar_pv.nil?
  end

  def storage_heaters?
    ! storage_heaters.nil?
  end

  def meter_corrections
    attributes(:meter_corrections)
  end

  def aggregation
    attributes(:aggregation)
  end

  def heating_model
    attributes(:heating_model)
  end

  def storage_heaters
    attributes(:storage_heaters)
  end

  def solar_pv
    attributes(:solar_pv)
  end

  def correct_mpan_check_digit?
    return true if gas?
    mpan = mpan_mprn.to_s
    primes = [3, 5, 7, 13, 17, 19, 23, 29, 31, 37, 41, 43]
    expected_check = (0..11).inject(0) { |sum, n| sum + (mpan[n, 1].to_i * primes[n]) } % 11 % 10
    expected_check.to_s == mpan.last
  end

  private

  def traditional_mpan?
    electricity? && ! @pseudo_mpan
  end

  def pseudo_mpan?
    electricity? && @pseudo_mpan
  end
end
