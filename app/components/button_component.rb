# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  VARIANTS = {
    primary: {
      bg: "bg-gray-900 theme-dark:bg-white hover:bg-gray-800 theme-dark:hover:bg-gray-50 disabled:bg-gray-500 theme-dark:disabled:bg-gray-400",
      fg: "text-white theme-dark:text-gray-900"
    },
    secondary: {
      bg: "bg-gray-50 theme-dark:bg-gray-700 hover:bg-gray-100 theme-dark:hover:bg-gray-600 disabled:bg-gray-200 theme-dark:disabled:bg-gray-600",
      fg: "text-gray-900 theme-dark:text-white"
    },
    outline: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      fg: "text-gray-900 theme-dark:text-white",
      border: "border border-gray-900 theme-dark:border-white"
    },
    outline_destructive: {
      bg: "bg-transparent hover:bg-red-100 theme-dark:hover:bg-red-700",
      fg: "text-destructive",
      border: "border border-red-500"
    },
    ghost: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      fg: "text-gray-900 theme-dark:text-white"
    },
    link_color: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      fg: "text-gray-900 theme-dark:text-white"
    },
    link_gray: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      fg: "text-gray-900 theme-dark:text-white"
    },
    icon: {
      bg: "bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700 rounded-lg",
      fg: "fg-gray"
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
      icon_container: "w-10 h-10",
      container: "px-3 py-2 rounded-lg",
      text: "text-sm",
      icon: "w-5 h-5"
    },
    lg: {
      icon_container: "w-12 h-12",
      container: "px-4 py-3 rounded-xl",
      text: "text-base",
      icon: "w-6 h-6"
    }
  }

  def initialize(text:, variant: "primary", size: "md", href: nil, leading_icon: nil, trailing_icon: nil, icon: nil, **options)
    @text = text
    @variant = variant.underscore.to_sym
    @size = size.to_sym
    @href = href
    @leading_icon = leading_icon
    @trailing_icon = trailing_icon
    @icon = icon
    @options = options
  end

  def wrapper_tag(&block)
    html_tag = @href ? "a" : "button"

    if @href.present?
      content_tag(html_tag, class: container_classes, href: @href, **@options, &block)
    else
      content_tag(html_tag, class: container_classes, **@options, &block)
    end
  end

  def text_classes
    [
      size_meta[:text],
      variant_meta[:fg]
    ].join(" ")
  end

  def icon_classes
    [
      size_meta[:icon],
      variant_meta[:fg]
    ].join(" ")
  end

  def icon_only?
    @variant == :icon
  end

  private
    def container_classes
      [
        "inline-flex items-center justify-center gap-1",
        @variant == :icon ? size_meta[:icon_container] : size_meta[:container],
        variant_meta[:bg]
      ].join(" ")
    end

    def size_meta
      SIZES[@size]
    end

    def variant_meta
      VARIANTS[@variant]
    end
end
