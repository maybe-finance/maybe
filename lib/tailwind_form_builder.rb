class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  include ActionView::Helpers::TagHelper

  class << self
    def has_styles_for(fields, style)
      @styles_for ||= {}

      fields = Array(fields)
      fields.each do |field|
        @styles_for[field] = style
      end
    end

    def styles_for
      @styles_for ||= {}
    end
  end

  (field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]).each do |selector|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{selector}(method, options = {})
        merged_opts = apply_classes(options, self.class.styles_for[:#{selector}])
        super(method, merged_opts)
      end
    RUBY_EVAL
  end

  def label(method, text = nil, options = {}, &block)
    merged_opts = apply_classes(options, self.class.styles_for[:label])
    super(method, text, merged_opts, &block)
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    merged_opts = apply_classes(options, self.class.styles_for[:check_box])
    super(method, merged_opts, checked_value, unchecked_value)
  end

  def radio_button(method, tag_value, options = {})
    merged_opts = apply_classes(options, self.class.styles_for[:radio_button])
    super(method, tag_value, merged_opts)
  end

  def hidden_field(method, options = {})
    merged_opts = apply_classes(options, self.class.styles_for[:hidden_field])
    super(method, merged_opts)
  end

  def file_field(method, options = {})
    merged_opts = apply_classes(options, self.class.styles_for[:file_field])
    super(method, merged_opts)
  end

  def submit(value = nil, options = {})
    value, options = nil, value if value.is_a?(Hash)
    merged_opts = apply_classes(options, self.class.styles_for[:submit])
    super(value, merged_opts)
  end

  def button(value = nil, options = {}, &block)
    case value
    when Hash
      value, options = nil, value
    when Symbol
      value, options = nil, { name: field_name(value), id: field_id(value) }.merge!(options.to_h)
    end

    merged_opts = apply_classes(options, self.class.styles_for[:button])
    super(value, merged_opts, &block)
  end

  private

  def apply_classes(options, *classes)
    options.merge({
      class: class_names(*classes, options[:class])
    })
  end
end
