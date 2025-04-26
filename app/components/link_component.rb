class LinkComponent < ViewComponent::Base
  include ButtonStylable

  attr_reader :href, :variant, :size, :text, :icon, :icon_position, :open_in, :opts

  VARIANTS = VARIANTS.merge(
    default: {
      container_classes: "",
      text_classes: "text-primary",
      icon_classes: "fg-gray"
    },
    link_destructive: {
      container_classes: "",
      text_classes: "text-destructive",
      icon_classes: "fg-destructive"
    }
  ).freeze

  def initialize(href:, variant: "default", size: "md", text: nil, icon: nil, icon_position: "left", rounded: false, full_width: false, open_in: nil, **opts)
    @href = href
    @variant = variant.underscore.to_sym
    @size = size.underscore.to_sym
    @text = text
    @icon = icon
    @icon_position = icon_position
    @rounded = rounded
    @full_width = full_width
    @open_in = open_in
    @opts = opts
  end

  def merged_opts
    merged_opts = opts.dup || {}
    extra_classes = merged_opts.delete(:class)
    data = merged_opts.delete(:data) || {}

    if open_in
      data = data.merge(turbo_frame: open_in)
    end

    merged_opts.merge(
      class: class_names(container_classes, extra_classes),
      data: data
    )
  end
end
