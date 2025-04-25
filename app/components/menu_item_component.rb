class MenuItemComponent < ViewComponent::Base
  erb_template <<~ERB
    <%= wrapper do %>
      <%= render IconComponent.new(@icon, variant: destructive? ? "destructive" : "default") %>
      <%= tag.span(@text, class: text_classes) %>
    <% end %>
  ERB

  VARIANTS = {
    link: {},
    action: {}
  }

  def initialize(text:, href:, variant: "link", method: :post, icon: nil, data: {})
    @text = text
    @icon = icon
    @href = href
    @variant = variant.to_sym
    @method = method
    @data = data
  end

  def wrapper(&block)
    case @variant
    when :link
      link_to @href, data: @data, class: container_classes, &block
    when :action
      button_to @href, method: @method, data: @data, class: container_classes, &block
    end
  end

  def text_classes
    [
      "text-sm",
      destructive? ? "text-destructive" : "text-primary"
    ].join(" ")
  end

  def destructive?
    @method == :delete
  end

  private
    def container_classes
      [
        "flex items-center gap-2 p-2 rounded-md w-full",
        destructive? ? "hover:bg-red-tint-5 theme-dark:hover:bg-red-tint-10" : "hover:bg-container-hover"
      ].join(" ")
    end
end
