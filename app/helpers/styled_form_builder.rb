class StyledFormBuilder < ActionView::Helpers::FormBuilder
  class_attribute :text_field_helpers, default: field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]

  text_field_helpers.each do |selector|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{selector}(method, options = {})
        form_options = options.slice(:label, :label_tooltip, :inline, :container_class, :required)
        html_options = options.except(:label, :label_tooltip, :inline, :container_class)

        build_field(method, form_options, html_options) do |merged_options|
          super(method, merged_options)
        end
      end
    RUBY_EVAL
  end

  def radio_button(method, tag_value, options = {})
    merged_options = { class: "form-field__radio" }.merge(options)
    super(method, tag_value, merged_options)
  end

  def select(method, choices, options = {}, html_options = {})
    field_options = normalize_options(options, html_options)

    build_field(method, field_options, html_options) do |merged_html_options|
      super(method, choices, options, merged_html_options)
    end
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    field_options = normalize_options(options, html_options)

    build_field(method, field_options, html_options) do |merged_html_options|
      super(method, collection, value_method, text_method, options, merged_html_options)
    end
  end

  def money_field(amount_method, options = {})
    @template.render partial: "shared/money_field", locals: {
      form: self,
      amount_method:,
      currency_method: options[:currency_method] || :currency,
      **options
    }
  end

  def toggle(method, options = {}, checked_value = "1", unchecked_value = "0")
    field_id = field_id(method)
    field_name = field_name(method)
    checked = object ? object.send(method) : options[:checked]

    @template.render(
      DS::Toggle.new(
        id: field_id,
        name: field_name,
        checked: checked,
        disabled: options[:disabled],
        checked_value: checked_value,
        unchecked_value: unchecked_value,
        **options
      )
    )
  end

  def submit(value = nil, options = {})
    value, options = nil, value if value.is_a?(Hash)
    value ||= submit_default_value

    @template.render(
      DS::Button.new(
        text: value,
        data: (options[:data] || {}).merge({ turbo_submits_with: "Submitting..." }),
        full_width: true
      )
    )
  end

  private
    def build_field(method, options = {}, html_options = {}, &block)
      if options[:inline] || options[:label] == false
        return yield({ class: "form-field__input" }.merge(html_options))
      end

      label_element = build_label(method, options)
      field_element = yield({ class: "form-field__input" }.merge(html_options))

      container_classes = [ "form-field", options[:container_class] ].compact

      @template.tag.div class: container_classes do
        if options[:label_tooltip]
          @template.tag.div(class: "form-field__header") do
            label_element +
            @template.tag.div(class: "form-field__actions") do
              build_tooltip(options[:label_tooltip])
            end
          end +
          @template.tag.div(class: "form-field__body") do
            field_element
          end
        else
          @template.tag.div(class: "form-field__body") do
            label_element + field_element
          end
        end
      end
    end

    def normalize_options(options, html_options)
      options.merge(required: options[:required] || html_options[:required])
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

    def build_tooltip(tooltip_text)
      return nil unless tooltip_text

      @template.tag.div(data: { controller: "tooltip" }) do
        @template.safe_join([
          @template.icon("help-circle", size: "sm", color: "default", class: "cursor-help"),
          @template.tag.div(tooltip_text, role: "tooltip", data: { tooltip_target: "tooltip" }, class: "tooltip bg-gray-700 text-sm p-2 rounded w-64 text-white")
        ])
      end
    end
end
