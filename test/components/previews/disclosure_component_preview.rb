class DisclosureComponentPreview < ViewComponent::Preview
  # @display container_classes max-w-[400px]
  # @param align select ["left", "right"]
  def default(align: "right")
    render DisclosureComponent.new(title: "Title", align: align, open: true) do |disclosure|
      disclosure.with_summary_content do
        content_tag(:p, "$200.25", class: "text-xs font-mono font-medium")
      end

      content_tag(:p, "Sample disclosure content", class: "text-sm")
    end
  end
end
