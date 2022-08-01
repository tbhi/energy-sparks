class ScoredSchoolsList
  include Enumerable

  def initialize(scored_schools)
    @scored_schools = scored_schools
  end

  def schools_with_positions
    list = {}
    @scored_schools.group_by(&:sum_points).each_with_index do |(_points, schools), index|
      list[index + 1] = schools
    end
    list
  end

  def position(school)
    schools_with_positions.select {|_position, schools| schools.include?(school)}.first.first
  end

  def top_three
    with_points.schools_at(0, 3)
  end

  def with_points
    self.class.new(@scored_schools.reject {|scored_school| scored_school.sum_points.nil? || scored_school.sum_points <= 0})
  end

  def without_points
    self.class.new(@scored_schools - with_points.to_a)
  end

  def index(school)
    @scored_schools.index(school)
  end

  def size
    @scored_schools.size
  end

  def schools_at(index, length)
    @scored_schools.slice(index, length)
  end

  def each
    @scored_schools.each {|school| yield school}
  end
end
