class IconComponentPreview < ViewComponent::Preview
  # @param variant select {{ IconComponent::VARIANTS.keys }}
  # @param size select {{ IconComponent::SIZES.keys }}
  def default(variant: "default", size: "md")
    render IconComponent.new(
      "circle-user",
      variant: variant,
      size: size
    )
  end
end
