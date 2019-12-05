# == Schema Information
#
# Table name: school_meter_attributes
#
#  attribute_type :string           not null
#  created_at     :datetime         not null
#  id             :bigint(8)        not null, primary key
#  input_data     :json
#  meter_type     :string           not null
#  reason         :text
#  school_id      :bigint(8)        not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_school_meter_attributes_on_school_id  (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id) ON DELETE => cascade
#

class SchoolMeterAttribute < ApplicationRecord
  belongs_to :school

  METER_TYPES = [:electricity, :gas].freeze

  def to_analytics
    meter_attribute_type.parse(input_data).to_analytics
  end

  def pseudo?
    meter_attribute_type.applicable_attribute_pseudo_meter_types.include?(meter_type.to_sym)
  end

  def meter_attribute_type
    MeterAttributes.all[attribute_type.to_sym]
  end
end
