class DS::Tabs < DesignSystemComponent
  renders_one :nav, ->(classes: nil) do
    DS::Tabs::Nav.new(
      active_tab: active_tab,
      active_btn_classes: active_btn_classes,
      inactive_btn_classes: inactive_btn_classes,
      btn_classes: base_btn_classes,
      classes: unstyled? ? classes : class_names(nav_container_classes, classes)
    )
  end

  renders_many :panels, ->(tab_id:, &block) do
    content_tag(
      :div,
      class: ("hidden" unless tab_id == active_tab),
      data: { id: tab_id, DS__tabs_target: "panel" },
      &block
    )
  end

  VARIANTS = {
    default: {
      active_btn_classes: "bg-white theme-dark:bg-gray-700 text-primary shadow-sm",
      inactive_btn_classes: "text-secondary hover:bg-surface-inset-hover",
      base_btn_classes: "w-full inline-flex justify-center items-center text-sm font-medium px-2 py-1 rounded-md transition-colors duration-200",
      nav_container_classes: "flex bg-surface-inset p-1 rounded-lg mb-4"
    }
  }

  attr_reader :active_tab, :url_param_key, :session_key, :variant, :testid

  def initialize(active_tab:, url_param_key: nil, session_key: nil, variant: :default, active_btn_classes: "", inactive_btn_classes: "", testid: nil)
    @active_tab = active_tab
    @url_param_key = url_param_key
    @session_key = session_key
    @variant = variant.to_sym
    @active_btn_classes = active_btn_classes
    @inactive_btn_classes = inactive_btn_classes
    @testid = testid
  end

  def active_btn_classes
    unstyled? ? @active_btn_classes : VARIANTS.dig(variant, :active_btn_classes)
  end

  def inactive_btn_classes
    unstyled? ? @inactive_btn_classes : VARIANTS.dig(variant, :inactive_btn_classes)
  end

  private
    def unstyled?
      variant == :unstyled
    end

    def base_btn_classes
      unless unstyled?
        VARIANTS.dig(variant, :base_btn_classes)
      end
    end

    def nav_container_classes
      unless unstyled?
        VARIANTS.dig(variant, :nav_container_classes)
      end
    end
end
