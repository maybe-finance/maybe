class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  def initialize(object_name, object, template, options)
    options[:html] ||= {}
    options[:html][:class] ||= "space-y-4"

    super(object_name, object, template, options)
  end

  (field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]).each do |selector|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{selector}(method, options = {})
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

  # See `Monetizable` concern, which adds a _money suffix to the attribute name
  # For a monetized field, the setter will always be the attribute name without the _money suffix
  def money_field(method, options = {})
    money = @object.send(method)
    raise ArgumentError, "The value of #{method} is not a Money object" unless money.is_a?(Money) || money.nil?

    money_amount_method = method.to_s.chomp("_money").to_sym
    money_currency_method = :currency

    readonly_currency = options[:readonly_currency] || false

    default_options = {
      class: "form-field__input",
      value: money&.amount,
      placeholder: Money.new(0, money&.currency || Money.default_currency).format
    }

    merged_options = default_options.merge(options)

    @template.form_field_tag do
      (label(method, *label_args(options)).to_s if options[:label]) +
      @template.tag.div(class: "flex items-center") do
        number_field(money_amount_method, merged_options.except(:label)) +
        select(money_currency_method, Money::Currency.popular.map(&:iso_code), { selected: money&.currency&.iso_code }, { disabled: readonly_currency, class: "ml-auto form-field__input w-fit pr-8" })
      end
    end
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

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    default_options = { class: "form-field__input" }
    merged_options = default_options.merge(html_options)

    return super(method, collection, value_method, text_method, options, merged_options) unless options[:label]

    @template.form_field_tag do
      label(method, *label_args(options)) +
      super(method, collection, value_method, text_method, options, merged_options.except(:label))
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
