# == Schema Information
#
# Table name: meter_attributes
#
#  attribute_type :string           not null
#  created_at     :datetime         not null
#  id             :bigint(8)        not null, primary key
#  input_data     :json
#  meter_id       :bigint(8)        not null
#  reason         :text
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_meter_attributes_on_meter_id  (meter_id)
#
# Foreign Keys
#
#  fk_rails_...  (meter_id => meters.id) ON DELETE => cascade
#

class MeterAttribute < ApplicationRecord
  belongs_to :meter

  def to_analytics
    meter_attribute_type.parse(input_data).to_analytics
  end

  def meter_attribute_type
    MeterAttributes.all[attribute_type.to_sym]
  end

  def self.to_analytics(meter_attributes)
    meter_attributes.inject({}) do |collection, attribute|
      aggregation = attribute.meter_attribute_type.attribute_aggregation
      if aggregation
        collection[aggregation] ||= []
        collection[aggregation] << attribute.to_analytics
        collection
      else
        collection.deep_merge(attribute.to_analytics)
      end
    end
  end
end
