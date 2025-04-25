# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  VARIANTS = {
    primary: {
      bg: "bg-inverse hover:bg-inverse-hover disabled:bg-gray-500 theme-dark:disabled:bg-gray-400",
      text: "text-white theme-dark:text-gray-900",
      icon: "fg-inverse"
    },
    secondary: {
      bg: "bg-gray-50 theme-dark:bg-gray-700 hover:bg-gray-100 theme-dark:hover:bg-gray-600 disabled:bg-gray-200 theme-dark:disabled:bg-gray-600",
      text: "text-gray-900 theme-dark:text-white",
      icon: "fg-primary"
    },
    destructive: {
      bg: "bg-red-500 theme-dark:bg-red-400 hover:bg-red-600 theme-dark:hover:bg-red-500 disabled:bg-red-200 theme-dark:disabled:bg-red-600",
      text: "text-white theme-dark:text-white",
      icon: "fg-white"
    },
    outline: {
      bg: "bg-transparent hover:bg-surface-hover",
      text: "text-gray-900 theme-dark:text-white",
      border: "border border-secondary",
      icon: "fg-gray"
    },
    outline_destructive: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      text: "text-destructive",
      border: "border border-secondary"
    },
    ghost: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      text: "text-primary",
      icon: "fg-gray"
    },
    link_color: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      text: "text-primary",
      icon: "fg-inverse"
    },
    link_gray: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      text: "text-secondary",
      icon: "fg-gray"
    },
    icon: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700 rounded-lg",
      text: "text-secondary",
      icon: "fg-gray"
    },
    icon_inverse: {
      bg: "bg-inverse hover:bg-inverse-hover rounded-lg",
      text: "fg-inverse",
      icon: "fg-inverse"
    }
  }.freeze

  SIZES = {
    sm: {
      icon_container: "w-8 h-8",
      container: "px-2 py-1 rounded-md",
      text: "text-sm",
      icon: "w-4 h-4"
    },
    md: {
      icon_container: "w-9 h-9",
      container: "px-3 py-2 rounded-lg",
      text: "text-sm",
      icon: "w-5 h-5"
    },
    lg: {
      icon_container: "w-10 h-10",
      container: "px-4 py-3 rounded-xl",
      text: "text-base",
      icon: "w-6 h-6"
    }
  }

  def initialize(options = {})
    @text = options.delete(:text)
    @variant = (options.delete(:variant) || "primary").underscore.to_sym
    @size = (options.delete(:size) || :md).to_sym
    @href = options.delete(:href)
    @method = options.delete(:method) || :get
    @leading_icon = options.delete(:leading_icon)
    @trailing_icon = options.delete(:trailing_icon)
    @icon = options.delete(:icon)
    @full_width = options.delete(:full_width)
    @left_align = options.delete(:left_align)
    @extra_classes = options.delete(:class)
    @options = options
  end

  def wrapper_tag(&block)
    if @href && @method != :get
      button_to @href, class: container_classes, method: @method, **@options, &block
    elsif @href
      link_to @href, class: container_classes, **@options, &block
    else
      content_tag :button, type: "button", class: container_classes, **@options, &block
    end
  end

  def icon_classes
    [
      "shrink-0",
      size_meta[:icon],
      variant_meta[:icon]
    ].join(" ")
  end

  def icon_only?
    @variant == :icon || @variant == :icon_inverse
  end

  private
    def container_classes
      hidden_override = (@extra_classes || "").split(" ").include?("hidden")
      default_classes = hidden_override ? "items-center gap-1" : "inline-flex items-center gap-1"

      [
        "whitespace-nowrap",
        default_classes,
        @full_width ? "w-full" : nil,
        @left_align ? "justify-start" : "justify-center",
        icon_only? ? size_meta[:icon_container] : size_meta[:container],
        variant_meta[:bg],
        variant_meta.dig(:border),
        text_classes,
        @extra_classes
      ].compact.join(" ")
    end

    def text_classes
      [
        "font-medium",
        size_meta[:text],
        variant_meta[:text]
      ].join(" ")
    end

    def size_meta
      SIZES[@size]
    end

    def variant_meta
      VARIANTS[@variant]
    end
end
