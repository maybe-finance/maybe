class ButtonComponentPreview < ViewComponent::Preview
  # @param variant select {{ ButtonComponent::VARIANTS.keys }}
  # @param size select {{ ButtonComponent::SIZES.keys }}
  # @param disabled toggle
  # @param leading_icon text
  # @param trailing_icon text
  # @param icon text "This is only used for icon-only buttons"
  def default(variant: "primary", size: "md", disabled: false, leading_icon: "plus", trailing_icon: nil, icon: "circle")
    render ButtonComponent.new(
      text: "Sample button",
      variant: variant,
      size: size,
      disabled: disabled,
      leading_icon: leading_icon,
      trailing_icon: trailing_icon,
      icon: icon
    )
  end
end
