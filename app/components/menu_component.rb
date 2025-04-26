# frozen_string_literal: true

class MenuComponent < ViewComponent::Base
  renders_one :button, ->(**options, &block) do
    options_with_target = options.merge(data: { menu_target: "button" })

    if block
      content_tag(:button, **options_with_target, &block)
    else
      ButtonComponent.new(**options_with_target)
    end
  end

  renders_one :header, ->(&block) do
    content_tag(:div, class: "border-b border-tertiary", &block)
  end

  renders_one :custom_content

  renders_many :items, MenuItemComponent

  VARIANTS = {
    icon: {},
    button: {},
    avatar: {}
  }

  def initialize(variant: "icon", avatar_url: nil, placement: "bottom-end", offset: 12, icon_vertical: false, data: {})
    @variant = variant.to_sym
    @avatar_url = avatar_url
    @placement = placement
    @offset = offset
    @icon_vertical = icon_vertical
    @data = data
  end

  def merged_data
    {
      controller: "menu",
      menu_placement_value: @placement,
      menu_offset_value: @offset
    }.merge(@data)
  end
end
