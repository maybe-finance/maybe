class DS::Tooltip < ApplicationComponent
  attr_reader :placement, :offset, :cross_axis, :icon_name, :size, :color

  def initialize(text: nil, placement: "top", offset: 10, cross_axis: 0, icon: "info", size: "sm", color: "default")
    @text = text
    @placement = placement
    @offset = offset
    @cross_axis = cross_axis
    @icon_name = icon
    @size = size
    @color = color
  end

  def tooltip_content
    content? ? content : @text
  end
end
