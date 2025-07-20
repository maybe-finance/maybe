class ToggleComponentPreview < ViewComponent::Preview
  # @param disabled toggle
  def default(disabled: false)
    render(
      DS::Toggle.new(
        id: "toggle-component-id",
        name: "toggle-component-name",
        checked: false,
        disabled: disabled,
        checked_value: "on",
        unchecked_value: "off"
      )
    )
  end
end
