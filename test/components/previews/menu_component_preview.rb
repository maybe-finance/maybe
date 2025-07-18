class MenuComponentPreview < ViewComponent::Preview
  def icon
    render DS::Menu.new(variant: "icon") do |menu|
      menu_contents(menu)
    end
  end

  def button
    render DS::Menu.new(variant: "button") do |menu|
      menu.with_button(text: "Open menu", variant: "secondary")
      menu_contents(menu)
    end
  end

  def avatar
    render DS::Menu.new(variant: "avatar") do |menu|
      menu_contents(menu)
    end
  end

  private
    def menu_contents(menu)
      menu.with_header do
        content_tag(:div, class: "p-3") do
          content_tag(:h3, "Menu header", class: "font-medium text-gray-900")
        end
      end

      menu.with_item(variant: "link", text: "Link", href: "#", icon: "plus")
      menu.with_item(variant: "button", text: "Action", href: "#", method: :post, icon: "circle")
      menu.with_item(variant: "button", text: "Action destructive", href: "#", method: :delete, icon: "circle")

      menu.with_item(variant: "divider")

      menu.with_custom_content do
        content_tag(:div, class: "p-4") do
          safe_join([
            content_tag(:h3, "Custom content header", class: "font-medium text-gray-900"),
            content_tag(:p, "Some custom content", class: "text-sm text-gray-500")
          ])
        end
      end
    end
end
