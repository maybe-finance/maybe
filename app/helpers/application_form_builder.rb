class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  (field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]).each do |selector|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{selector}(method, options)
        default_options = { class: "form-field__input" }
        merged_options = default_options.merge(options)

        return super(method, merged_options) unless options[:label]

        @template.form_field_tag do
          label(method, *label_args(options)) +
          super(method, merged_options.except(:label))
        end
      end
    RUBY_EVAL
  end

  def select(method, choices, options = {}, html_options = {})
    default_options = { class: "form-field__input" }
    merged_options = default_options.merge(html_options)

    return super(method, choices, options, merged_options) unless options[:label]

    @template.form_field_tag do
      label(method, *label_args(options)) +
      super(method, choices, options, merged_options.except(:label))
    end
  end

  def submit(value = nil, options = {})
    value, options = nil, value if value.is_a?(Hash)
    default_options = { class: "form-field__submit" }
    merged_options = default_options.merge(options)
    super(value, merged_options)
  end

  private

  def label_args(options)
    case options[:label]
    when Array
      options[:label]
    when String
      [ options[:label], { class: "form-field__label" } ]
    when Hash
      [ nil, options[:label] ]
    else
      [ nil, { class: "form-field__label" } ]
    end
  end
end
