# frozen_string_literal: true

class MenuComponent < ViewComponent::Base
  renders_one :button, ->(**options) do
    options_with_target = options.merge(data: { menu_target: "button" })
    ButtonComponent.new(**options_with_target)
  end

  renders_many :items, MenuItemComponent

  VARIANTS = {
    icon: {},
    button: {}
  }

  def initialize(variant: "icon")
    @variant = variant.to_sym
  end
end
