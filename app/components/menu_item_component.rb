class MenuItemComponent < ViewComponent::Base
  VARIANTS = %i[link button divider].freeze

  attr_reader :variant, :text, :icon, :href, :method, :destructive, :confirm, :opts

  def initialize(variant:, text: nil, icon: nil, href: nil, method: :post, destructive: false, confirm: nil, **opts)
    @variant = variant.to_sym
    @text = text
    @icon = icon
    @href = href
    @method = method.to_sym
    @destructive = destructive
    @opts = opts
    @confirm = confirm
    raise ArgumentError, "Invalid variant: #{@variant}" unless VARIANTS.include?(@variant)
  end

  def wrapper(&block)
    if variant == :button
      button_to href, method: method, class: container_classes, **merged_button_opts, &block
    elsif variant == :link
      link_to href, class: container_classes, **opts, &block
    else
      nil
    end
  end

  def text_classes
    [
      "text-sm",
      destructive? ? "text-destructive" : "text-primary"
    ].join(" ")
  end

  def destructive?
    method == :delete || destructive
  end

  private
    def container_classes
      [
        "flex items-center gap-2 p-2 rounded-md w-full",
        destructive? ? "hover:bg-red-tint-5 theme-dark:hover:bg-red-tint-10" : "hover:bg-container-hover"
      ].join(" ")
    end

    def merged_button_opts
      merged_opts = opts.dup || {}
      data = merged_opts.delete(:data) || {}

      if confirm.present?
        data = data.merge(turbo_confirm: confirm.to_data_attribute)
      end

      merged_opts.merge(data: data)
    end
end
