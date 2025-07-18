class DS::Dialog < DesignSystemComponent
  renders_one :header, ->(title: nil, subtitle: nil, hide_close_icon: false, **opts, &block) do
    content_tag(:header, class: "px-4 flex flex-col gap-2", **opts) do
      title_div = content_tag(:div, class: "flex items-center justify-between gap-2") do
        title = content_tag(:h2, title, class: class_names("font-medium text-primary", drawer? ? "text-lg" : "")) if title
        close_icon = render DS::Button.new(variant: "icon", class: "ml-auto", icon: "x", tabindex: "-1", data: { action: "DS--dialog#close" }) unless hide_close_icon
        safe_join([ title, close_icon ].compact)
      end

      subtitle = content_tag(:p, subtitle, class: "text-sm text-secondary") if subtitle

      block_content = capture(&block) if block

      safe_join([ title_div, subtitle, block_content ].compact)
    end
  end

  renders_one :body

  renders_many :actions, ->(cancel_action: false, **button_opts) do
    merged_opts = if cancel_action
      button_opts.merge(type: "button", data: { action: "DS--dialog#close" })
    else
      button_opts
    end

    render DS::Button.new(**merged_opts)
  end

  renders_many :sections, ->(title:, **disclosure_opts, &block) do
    render DS::Disclosure.new(title: title, align: :right, **disclosure_opts) do
      block.call
    end
  end

  attr_reader :variant, :auto_open, :reload_on_close, :width, :disable_frame, :opts

  VARIANTS = %w[modal drawer].freeze
  WIDTHS = {
    sm: "lg:max-w-[300px]",
    md: "lg:max-w-[550px]",
    lg: "lg:max-w-[700px]",
    full: "lg:max-w-full"
  }.freeze

  def initialize(variant: "modal", auto_open: true, reload_on_close: false, width: "md", frame: nil, disable_frame: false, **opts)
    @variant = variant.to_sym
    @auto_open = auto_open
    @reload_on_close = reload_on_close
    @width = width.to_sym
    @frame = frame
    @disable_frame = disable_frame
    @opts = opts
  end

  def frame
    @frame || variant
  end

  # Caller must "opt-out" of using the default turbo-frame based on the variant
  def wrapper_element(&block)
    if disable_frame
      content_tag(:div, &block)
    else
      content_tag("turbo-frame", id: frame, &block)
    end
  end

  def dialog_outer_classes
    variant_classes = if drawer?
      "items-end justify-end"
    else
      "items-center justify-center"
    end

    class_names(
      "flex h-full w-full",
      variant_classes
    )
  end

  def dialog_inner_classes
    variant_classes = if drawer?
      "lg:w-[550px] h-full"
    else
      class_names(
        "max-h-full",
        WIDTHS[width]
      )
    end

    class_names(
      "flex flex-col bg-container rounded-xl shadow-border-xs mx-3 lg:mx-0 w-full overflow-hidden",
      variant_classes
    )
  end

  def merged_opts
    merged_opts = opts.dup
    data = merged_opts.delete(:data) || {}

    data[:controller] = [ "DS--dialog", "hotkey", data[:controller] ].compact.join(" ")
    data[:DS__dialog_auto_open_value] = auto_open
    data[:DS__dialog_reload_on_close_value] = reload_on_close
    data[:action] = [ "mousedown->DS--dialog#clickOutside", data[:action] ].compact.join(" ")
    data[:hotkey] = "esc:DS--dialog#close"
    merged_opts[:data] = data

    merged_opts
  end

  def drawer?
    variant == :drawer
  end
end
