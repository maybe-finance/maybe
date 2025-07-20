class DS::Alert < DesignSystemComponent
  def initialize(message:, variant: :info)
    @message = message
    @variant = variant
  end

  private
    attr_reader :message, :variant

    def container_classes
      base_classes = "flex items-start gap-3 p-4 rounded-lg border"

      variant_classes = case variant
      when :info
        "bg-blue-50 text-blue-700 border-blue-200 theme-dark:bg-blue-900/20 theme-dark:text-blue-400 theme-dark:border-blue-800"
      when :success
        "bg-green-50 text-green-700 border-green-200 theme-dark:bg-green-900/20 theme-dark:text-green-400 theme-dark:border-green-800"
      when :warning
        "bg-yellow-50 text-yellow-700 border-yellow-200 theme-dark:bg-yellow-900/20 theme-dark:text-yellow-400 theme-dark:border-yellow-800"
      when :error, :destructive
        "bg-red-50 text-red-700 border-red-200 theme-dark:bg-red-900/20 theme-dark:text-red-400 theme-dark:border-red-800"
      end

      "#{base_classes} #{variant_classes}"
    end

    def icon_name
      case variant
      when :info
        "info"
      when :success
        "check-circle"
      when :warning
        "alert-triangle"
      when :error, :destructive
        "x-circle"
      end
    end

    def icon_color
      case variant
      when :success
        "success"
      when :warning
        "warning"
      when :error, :destructive
        "destructive"
      else
        "blue-600"
      end
    end
end
