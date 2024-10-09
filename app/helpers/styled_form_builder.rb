class StyledFormBuilder < ActionView::Helpers::FormBuilder
  # Fields that visually inherit from "text field"
  class_attribute :text_field_helpers, default: field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]

  # Wraps "text" inputs with custom structure + base styles
  text_field_helpers.each do |selector|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{selector}(method, options = {})
        merged_options = { class: "form-field__input" }.merge(options)
        label = build_label(method, options)
        field = super(method, merged_options)

        build_styled_field(label, field, merged_options)
      end
    RUBY_EVAL
  end

  def radio_button(method, tag_value, options = {})
    merged_options = { class: "form-field__radio" }.merge(options)

    super(method, tag_value, merged_options)
  end

  def select(method, choices, options = {}, html_options = {})
    merged_html_options = { class: "form-field__input" }.merge(html_options)

    label = build_label(method, options)
    field = super(method, choices, options, merged_html_options)

    build_styled_field(label, field, options, remove_padding_right: true)
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    merged_html_options = { class: "form-field__input" }.merge(html_options)

    label = build_label(method, options)
    field = super(method, collection, value_method, text_method, options, merged_html_options)

    build_styled_field(label, field, options, remove_padding_right: true)
  end

  def money_field(amount_method, options = {})
    @template.render partial: "shared/money_field", locals: {
      form: self,
      amount_method:,
      currency_method: options[:currency_method] || :currency,
      **options
    }
  end

  def submit(value = nil, options = {})
    merged_options = { class: "btn btn--primary w-full" }.merge(options)
    value, options = nil, value if value.is_a?(Hash)
    super(value, merged_options)
  end

  private

    def build_styled_field(label, field, options, remove_padding_right: false)
      if options[:inline]
        label + field
      else
        @template.tag.div class: [ "form-field", options[:container_class], ("pr-0" if remove_padding_right) ] do
          label + field
        end
      end
    end

    def build_label(method, options)
      return "".html_safe unless options[:label]
      return label(method, class: "form-field__label") if options[:label] == true
      label(method, options[:label], class: "form-field__label")
    end
end
