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

    label = build_label(method, options.merge(required: merged_html_options[:required]))
    field = super(method, choices, options, merged_html_options)

    build_styled_field(label, field, options, remove_padding_right: true)
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    merged_html_options = { class: "form-field__input" }.merge(html_options)

    label = build_label(method, options.merge(required: merged_html_options[:required]))
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

  # A custom styled "toggle" switch input.  Underlying input is a `check_box` (uses same API)
  def toggle(method, options = {}, checked_value = "1", unchecked_value = "0")
    if object
      id = "#{object.id}_#{object_name}_#{method}"
      name = "#{object_name}[#{method}]"
      checked = object.send(method)
    else
      id = "#{method}_toggle_id"
      name = method
      checked = options[:checked]
    end

    @template.render(
      ToggleComponent.new(
        id: id,
        name: name,
        checked: checked,
        disabled: options[:disabled],
        checked_value: checked_value,
        unchecked_value: unchecked_value,
        **options
      )
    )
  end

  def submit(value = nil, options = {})
    # Rails superclass logic to extract the submit text
    value, options = nil, value if value.is_a?(Hash)
    value ||= submit_default_value

    @template.render(
      ButtonComponent.new(
        text: value,
        data: (options[:data] || {}).merge({ turbo_submits_with: "Submitting..." }),
        full_width: true
      )
    )
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

      label_text = options[:label]

      if options[:required]
        label_text = @template.safe_join([
          label_text == true ? method.to_s.humanize : label_text,
          @template.tag.span("*", class: "text-red-500 ml-0.5")
        ])
      end

      return label(method, class: "form-field__label") if label_text == true
      label(method, label_text, class: "form-field__label")
    end
end
