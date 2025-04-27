# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  include ButtonStylable

  attr_reader :text, :icon, :icon_position

  def initialize(text: nil, variant: "primary", size: "md", icon: nil, icon_position: "left", full_width: false, rounded: false, confirm: nil, **opts)
    @text = text
    @variant = variant.underscore.to_sym
    @size = size.to_sym
    @icon = icon
    @icon_position = icon_position
    @full_width = full_width
    @rounded = rounded
    @confirm = confirm
    @opts = opts
  end

  def container(&block)
    if href.present?
      button_to(href, **merged_opts, &block)
    else
      content_tag(:button, **merged_opts, &block)
    end
  end

  private
    attr_reader :variant, :size, :rounded, :full_width, :confirm, :opts

    def href
      opts[:href]
    end

    def merged_opts
      merged_opts = opts.dup || {}
      extra_classes = merged_opts.delete(:class)
      href = merged_opts.delete(:href)
      data = merged_opts.delete(:data) || {}

      if confirm.present?
        data = data.merge(turbo_confirm: confirm.to_data_attribute)
      end

      merged_opts.merge(
        class: class_names(container_classes, extra_classes),
        data: data
      )
    end
end
