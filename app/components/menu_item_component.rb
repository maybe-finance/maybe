class MenuItemComponent < ViewComponent::Base
  erb_template <<~ERB
    <% if @variant == :divider %>
      <hr class="border-tertiary my-1">
    <% else %>
      <div class="px-1">
        <%= wrapper do %>
          <% if @icon %>
            <%= render IconComponent.new(@icon, variant: destructive? ? "destructive" : "default") %>
          <% end %>
          <%= tag.span(@text, class: text_classes) %>
        <% end %>
      </div>
    <% end %>
  ERB

  def initialize(variant: "default", text: nil, href: nil, method: :get, icon: nil, data: {})
    @variant = variant.to_sym
    @text = text
    @icon = icon
    @href = href
    @method = method.to_sym
    @data = data
  end

  def wrapper(&block)
    if @method.in?([ :post, :patch, :delete ])
      button_to @href, method: @method, data: @data, class: container_classes, &block
    else
      link_to @href, data: @data, class: container_classes, &block
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
