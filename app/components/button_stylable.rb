module ButtonStylable
  VARIANTS = {
    primary: {
      container_classes: "text-inverse bg-inverse hover:bg-inverse-hover disabled:bg-gray-500 theme-dark:disabled:bg-gray-400",
      icon_classes: "fg-inverse"
    },
    secondary: {
      container_classes: "text-secondary bg-gray-50 theme-dark:bg-gray-700 hover:bg-gray-100 theme-dark:hover:bg-gray-600 disabled:bg-gray-200 theme-dark:disabled:bg-gray-600",
      icon_classes: "fg-primary"
    },
    destructive: {
      container_classes: "text-inverse bg-red-500 theme-dark:bg-red-400 hover:bg-red-600 theme-dark:hover:bg-red-500 disabled:bg-red-200 theme-dark:disabled:bg-red-600",
      icon_classes: "fg-white"
    },
    outline: {
      container_classes: "text-primary border border-secondary bg-transparent hover:bg-surface-hover",
      icon_classes: "fg-gray"
    },
    outline_destructive: {
      container_classes: "text-destructive border border-secondary bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      icon_classes: "fg-gray"
    },
    ghost: {
      container_classes: "text-primary bg-transparent hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      icon_classes: "fg-gray"
    },
    icon: {
      container_classes: "hover:bg-gray-100 theme-dark:hover:bg-gray-700",
      icon_classes: "fg-gray"
    },
    icon_inverse: {
      container_classes: "bg-inverse hover:bg-inverse-hover",
      icon_classes: "fg-inverse"
    }
  }.freeze

  SIZES = {
    sm: {
      padding_classes: "px-2 py-1",
      icon_padding_classes: "p-2",
      radius_classes: "rounded-md",
      text_classes: "text-sm",
      icon_classes: "w-4 h-4"
    },
    md: {
      padding_classes: "px-3 py-2",
      icon_padding_classes: "p-2",
      radius_classes: "rounded-lg",
      text_classes: "text-sm",
      icon_classes: "w-5 h-5"
    },
    lg: {
      padding_classes: "px-4 py-3",
      icon_padding_classes: "p-2",
      radius_classes: "rounded-xl",
      text_classes: "text-base",
      icon_classes: "w-6 h-6"
    }
  }.freeze

  def container_classes
    class_names(
      "inline-flex items-center gap-1 font-medium whitespace-nowrap",
      full_width ? "w-full justify-center" : "",
      icon_only? ? SIZES.dig(size, :icon_padding_classes) : SIZES.dig(size, :padding_classes),
      rounded ? "rounded-full" : SIZES.dig(size, :radius_classes),
      SIZES.dig(size, :text_classes),
      VARIANTS.dig(variant, :container_classes)
    )
  end

  def icon_classes
    class_names(
      SIZES.dig(size, :icon_classes),
      VARIANTS.dig(variant, :icon_classes)
    )
  end

  def icon_only?
    variant.in?([ :icon, :icon_inverse ])
  end

  private
    def full_width
      @full_width ||= false
    end

    def rounded
      @rounded ||= false
    end

    def variant
      @variant ||= :primary
    end

    def size
      @size ||= :md
    end
end
