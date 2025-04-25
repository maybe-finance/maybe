class MenuComponentPreview < ViewComponent::Preview
  # @param variant select {{ MenuComponent::VARIANTS.keys }}
  def default(variant: "icon")
    if variant == "icon"
      render MenuComponent.new(variant: variant) do |menu|
        menu.with_item(text: "Menu item 1", href: "#", icon: "plus")
        menu.with_item(text: "Menu item 2", href: "#", icon: "circle")
        menu.with_item(text: "Destructive", href: "#", method: :delete, icon: "circle")
      end
    else
      render MenuComponent.new(variant: variant) do |menu|
        menu.with_button(text: "New", icon: "plus")
        menu.with_item(text: "Menu item 1", href: "#", icon: "plus")
        menu.with_item(text: "Menu item 2", href: "#", icon: "circle")
        menu.with_item(text: "Destructive", href: "#", method: :delete, icon: "circle")
      end
    end
  end
end
