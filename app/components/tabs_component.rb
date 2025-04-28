class TabsComponent < ViewComponent::Base
  renders_many :tabs, TabComponent

  VARIANTS = {
    default: {
      nav_btn_active_classes: "bg-white theme-dark:bg-gray-700 text-primary shadow-sm",
      nav_btn_inactive_classes: "text-secondary hover:bg-surface-inset-hover",
      nav_btn_classes: "w-full inline-flex justify-center items-center text-sm font-medium px-2 py-1 rounded-md transition-colors duration-200"
    }
  }

  attr_reader :variant, :url_param_key

  def initialize(active_tab: nil, variant: "default", url_param_key: nil)
    @active_tab = active_tab
    @variant = variant.to_sym
    @url_param_key = url_param_key
  end

  def active_tab
    @active_tab || tabs.first.id
  end

  def nav_btn_active_classes
    VARIANTS.dig(variant, :nav_btn_active_classes)
  end

  def nav_btn_inactive_classes
    VARIANTS.dig(variant, :nav_btn_inactive_classes)
  end

  def nav_btn_classes(active: false)
    class_names(
      VARIANTS.dig(variant, :nav_btn_classes),
      active ? nav_btn_active_classes : nav_btn_inactive_classes
    )
  end
end
