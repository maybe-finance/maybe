class ButtonComponentPreview < ViewComponent::Preview
  # @param variant select {{ ButtonComponent::VARIANTS.keys }}
  # @param size select {{ ButtonComponent::SIZES.keys }}
  # @param disabled toggle
  # @param icon select ["plus", "circle"]
  # @param rounded toggle
  def default(variant: "primary", size: "md", disabled: false, icon: "plus", rounded: false)
    render ButtonComponent.new(
      text: "Sample button",
      variant: variant,
      size: size,
      disabled: disabled,
      icon: icon,
      rounded: rounded,
      data: { menu_target: "button" }
    )
  end
end
