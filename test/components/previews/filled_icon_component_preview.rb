class FilledIconComponentPreview < ViewComponent::Preview
  # @param size select ["sm", "md", "lg"]
  def default(size: "md")
    render DS::FilledIcon.new(icon: "home", variant: :default, size: size)
  end

  # @param size select ["sm", "md", "lg"]
  def text(size: "md")
    render DS::FilledIcon.new(variant: :text, text: "Test", size: size, rounded: true)
  end
end
