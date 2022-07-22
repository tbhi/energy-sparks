# == Schema Information
#
# Table name: transport_surveys
#
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  run_on     :date             not null
#  school_id  :bigint(8)        not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_transport_surveys_on_school_id             (school_id)
#  index_transport_surveys_on_school_id_and_run_on  (school_id,run_on) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id) ON DELETE => cascade
#
class TransportSurvey < ApplicationRecord
  belongs_to :school
  has_many :responses, class_name: 'TransportSurveyResponse', inverse_of: :transport_survey

  validates :run_on, :school_id, presence: true
  validates :run_on, uniqueness: { scope: :school_id }

  def to_param
    run_on.to_s
  end

  def total_responses
    self.responses.count
  end

  def total_carbon
    self.responses.sum(&:carbon)
  end

  def today?
    run_on == Time.zone.today
  end

  def responses_per_category
    responses_per_cat = self.responses.with_transport_type.group(:category).count
    TransportType.categories_with_other.transform_values { |v| responses_per_cat[v] || 0 }
  end

  def percentage_per_category
    responses_per_category.transform_values { |v| v == 0 ? 0 : (v.to_f / total_responses * 100) }
  end

  def pie_chart_data
    percentage_per_category.collect { |k, v| { name: TransportType.human_enum_name(:category, k), y: v } }
  end

  def self.equivalence_images
    { tree: '🌳', tv: '📺', computer_console: '🎮', smartphone: '📱', carnivore_dinner: '🍲', vegetarian_dinner: '🥗' }
  end

  def self.equivalence_svgs
    { tree: 'tree', tv: 'television', computer_console: 'video_game', smartphone: 'phone', carnivore_dinner: 'roast_meal', vegetarian_dinner: 'meal' }
  end

  def self.equivalence_devisors
    { tree: 365 }
  end

  def self.equivalences
    equivalence_images.collect do |name, image|
      { rate: EnergyEquivalences.all_equivalences[name][:conversions][:co2][:rate] / (equivalence_devisors[name] || 1),
        statement: I18n.t(name, scope: 'schools.transport_surveys.equivalences'),
        image: image,
        name: name }
    end
  end

  def equivalences
    self.class.equivalences.collect do |equivalence|
      amount = (total_carbon / equivalence[:rate]).round
      if amount > 0
        { name: equivalence[:name],
          statement: I18n.t(equivalence[:name], scope: 'schools.transport_surveys.equivalences', image: equivalence[:image], amount: amount, count: amount),
          svg: self.class.equivalence_svgs[equivalence[:name]] }
      end
    end.compact.shuffle
  end

  def responses=(responses_attributes)
    responses_attributes.each do |response_attributes|
      self.responses.create_with(response_attributes).find_or_create_by(response_attributes.slice(:run_identifier, :surveyed_at))
    end
  end
end
