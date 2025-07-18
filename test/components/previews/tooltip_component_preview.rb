class TooltipComponentPreview < ViewComponent::Preview
  # @param text text
  # @param placement select [top, right, bottom, left]
  # @param offset number
  # @param cross_axis number
  # @param icon text
  # @param size select [xs, sm, md, lg, xl, 2xl]
  # @param color select [default, white, success, warning, destructive, current]
  def default(text: "This is helpful information", placement: "top", offset: 10, cross_axis: 0, icon: "info", size: "sm", color: "default")
    render DS::Tooltip.new(
      text: text,
      placement: placement,
      offset: offset,
      cross_axis: cross_axis,
      icon: icon,
      size: size,
      color: color
    )
  end

  def with_block_content
    render DS::Tooltip.new(icon: "help-circle", color: "warning") do
      tag.div do
        tag.p("Custom content with formatting:", class: "font-medium mb-1") +
        tag.ul(class: "list-disc list-inside text-xs") do
          tag.li("First item") +
          tag.li("Second item")
        end
      end
    end
  end
end
