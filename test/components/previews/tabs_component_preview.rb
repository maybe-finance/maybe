class TabsComponentPreview < ViewComponent::Preview
  # @display container_classes max-w-[400px]
  def default
    render TabsComponent.new(active_tab: "tab1") do |container|
      container.with_tab(id: "tab1", label: "Tab 1") do
        content_tag(:p, "Content for tab 1")
      end

      container.with_tab(id: "tab2", label: "Tab 2") do
        content_tag(:p, "Content for tab 2")
      end
    end
  end
end
