# frozen_string_literal: true

class PanelSwitcherComponent < ViewComponent::Base
  attr_reader :title, :description, :classes, :id, :name

  renders_many :panels, "PanelComponent"

  def initialize(title: nil, description: nil, selected: nil, classes: '', id: nil)
    @title = title
    @description = description
    @selected = selected
    @classes = classes
    @id = id
    @name = title.try(:parameterize) || SecureRandom.uuid
  end

  def selected
    @selected.blank? || !selected_panel_exists? ? panels.first.name : @selected
  end

  def render?
    panels.any?
  end

  private

  def selected_panel_exists?
    panels.map(&:name).include?(@selected)
  end

  class PanelComponent < ViewComponent::Base
    attr_accessor :label, :name

    def initialize(label:, name:)
      @name = name
      @label = label
    end

    def call
      content
    end
  end
end
