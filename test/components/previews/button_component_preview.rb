class ButtonComponentPreview < ViewComponent::Preview
  # @param variant select {{ DS::Button::VARIANTS.keys }}
  # @param size select {{ DS::Button::SIZES.keys }}
  # @param disabled toggle
  # @param icon select ["plus", "circle"]
  def default(variant: "primary", size: "md", disabled: false, icon: "plus")
    render DS::Button.new(
      text: "Sample button",
      variant: variant,
      size: size,
      disabled: disabled,
      icon: icon,
      data: { menu_target: "button" }
    )
  end
end
