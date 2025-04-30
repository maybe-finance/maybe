class FilledIconComponentPreview < ViewComponent::Preview
  # @param size select ["sm", "md", "lg"]
  def default(size: "md")
    render FilledIconComponent.new(icon: "home", variant: :default, size: size)
  end

  # @param size select ["sm", "md", "lg"]
  def text(size: "md")
    render FilledIconComponent.new(variant: :text, text: "Test", size: size, rounded: true)
  end
end
