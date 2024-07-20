class StyledFormBuilder < ActionView::Helpers::FormBuilder
  # Fields that visually inherit from "text field"
  class_attribute :text_field_helpers, default: field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]

  # Wraps "text" inputs with custom structure + base styles
  text_field_helpers.each do |selector|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{selector}(method, options = {})
        input_html = label_html(method, options) + super(method, merged_options(options))
        input_html = apply_form_field_wrapper(input_html) unless options[:inline]
        input_html
      end
    RUBY_EVAL
  end

  def radio_button(method, tag_value, options = {})
    super(method, tag_value, merged_options(options, "form-field__radio"))
  end

  def select(method, choices, options = {}, html_options = {})
    input_html = label_html(method, options) + super(method, choices, options, merged_options(html_options))
    input_html = apply_form_field_wrapper(input_html, class: "pr-0") unless options[:inline]
    input_html
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    input_html = label_html(method, options) + super(method, collection, value_method, text_method, options, merged_options(html_options))
    input_html = apply_form_field_wrapper(input_html, class: "pr-0") unless options[:inline]
    input_html
  end

  def submit(value = nil, options = {})
    value, options = nil, value if value.is_a?(Hash)
    super(value, merged_options(options, "form-field__submit"))
  end

  private

    def apply_form_field_wrapper(input_html, **options)
      @template.form_field_tag(**options) do
        input_html
      end
    end

    def merged_options(options, default_class = "form-field__input")
      combined_classes = options.fetch(:class, "") + " #{default_class}"
      style_options = { class: combined_classes }
      non_custom_options = options.except(:class, :label, :inline)
      style_options.merge(non_custom_options)
    end

    def label_html(method, options)
      return label(method, class: "form-field__label") if options[:label] == true
      options[:label] ? label(method, options[:label], class: "form-field__label") : "".html_safe
    end
end
