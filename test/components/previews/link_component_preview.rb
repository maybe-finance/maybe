class LinkComponentPreview < ViewComponent::Preview
  # Usage
  # -------------
  #
  # LinkComponent is a small abstraction on top of the `link_to` helper.
  #
  # It can be used as a regular link or styled as a "Link button" using any of the available ButtonComponent variants.
  #
  # @param variant select {{ LinkComponent::VARIANTS.keys }}
  # @param size select {{ LinkComponent::SIZES.keys }}
  # @param icon select ["", "plus", "arrow-right"]
  # @param icon_position select ["left", "right"]
  # @param full_width toggle
  def default(variant: "default", size: "md", icon: "plus", icon_position: "left", full_width: false)
    render LinkComponent.new(
      href: "#",
      text: "Preview link",
      variant: variant,
      size: size,
      icon: icon,
      icon_position: icon_position,
      full_width: full_width
    )
  end
end
