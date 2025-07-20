# frozen_string_literal: true

class DS::Menu < DesignSystemComponent
  attr_reader :variant, :avatar_url, :initials, :placement, :offset, :icon_vertical, :no_padding, :testid

  renders_one :button, ->(**button_options, &block) do
    options_with_target = button_options.merge(data: { DS__menu_target: "button" })

    if block
      content_tag(:button, **options_with_target, &block)
    else
      DS::Button.new(**options_with_target)
    end
  end

  renders_one :header, ->(&block) do
    content_tag(:div, class: "border-b border-tertiary", &block)
  end

  renders_one :custom_content

  renders_many :items, DS::MenuItem

  VARIANTS = %i[icon button avatar].freeze

  def initialize(variant: "icon", avatar_url: nil, initials: nil, placement: "bottom-end", offset: 12, icon_vertical: false, no_padding: false, testid: nil)
    @variant = variant.to_sym
    @avatar_url = avatar_url
    @initials = initials
    @placement = placement
    @offset = offset
    @icon_vertical = icon_vertical
    @no_padding = no_padding
    @testid = testid

    raise ArgumentError, "Invalid variant: #{@variant}" unless VARIANTS.include?(@variant)
  end
end
