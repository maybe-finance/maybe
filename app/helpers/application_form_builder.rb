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

    currency = money&.currency || Money::Currency.new(Current.family.currency)  || Money.default_currency
    default_options = {
      class: "form-field__input",
      value: money&.amount,
      "data-money-field-target" => "amount",
      placeholder: Money.new(0, currency).format,
      min: -99999999999999,
      max: 99999999999999,
      step: currency.step
    }

    merged_options = default_options.merge(options)

    grouped_options = currency_options_for_select
    selected_currency = money&.currency&.iso_code || currency.iso_code

    @template.form_field_tag data: { controller: "money-field" } do
      (label(method, *label_args(options)).to_s if options[:label]) +
        @template.tag.div(class: "flex items-center") do
          number_field(money_amount_method, merged_options.except(:label)) +
            grouped_select(money_currency_method, grouped_options, { selected: selected_currency, disabled: readonly_currency }, class: "ml-auto form-field__input w-fit pr-8", data: { "money-field-target" => "currency", action: "change->money-field#handleCurrencyChange" })
        end
    end
  end

  def radio_button(method, tag_value, options = {})
    default_options = { class: "form-field__radio" }
    merged_options = default_options.merge(options)
    super(method, tag_value, merged_options)
  end

  def grouped_select(method, grouped_choices, options = {}, html_options = {})
    default_options = { class: "form-field__input" }
    merged_html_options = default_options.merge(html_options)

    label_html = label(method, *label_args(options)).to_s if options[:label]
    select_html = @template.grouped_collection_select(@object_name, method, grouped_choices, :last, :first, :last, :first, options, merged_html_options)

    @template.content_tag(:div, class: "flex items-center") do
      label_html.to_s.html_safe + select_html
    end
  end

  def currency_select(method, options = {}, html_options = {})
    default_options = { class: "form-field__input" }
    merged_options = default_options.merge(html_options)

    choices = currency_options_for_select

    return @template.grouped_collection_select(@object_name, method, choices, :last, :first, :last, :first, options, merged_options) unless options[:label]

    @template.form_field_tag do
      label(method, *label_args(options)) +
        @template.grouped_collection_select(@object_name, method, choices, :last, :first, :last, :first, options, merged_options.except(:label))
    end
  end

  def language_select(method, options = {}, html_options = {})
    default_options = { class: "form-field__input" }
    merged_options = default_options.merge(html_options)

    choices = I18n.available_locales.map { |locale| [I18n.t("settings.preferences.language.#{locale}", default: locale.to_s.capitalize), locale] }

    return @template.select(@object_name, method, choices, options, merged_options) unless options[:label]

    @template.form_field_tag do
      label(method, *label_args(options)) +
        @template.select(@object_name, method, choices, options, merged_options.except(:label))
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

    def currency_options_for_select
      popular_currencies = Money::Currency.popular.map { |currency| [ currency.iso_code, currency.iso_code ] }
      all_currencies = Money::Currency.all_instances.map { |currency| [ currency.iso_code, currency.iso_code ] }
      all_other_currencies = all_currencies.reject { |c| popular_currencies.map(&:last).include?(c.last) }.sort_by(&:last)

      {
        I18n.t("accounts.new.currency.popular") => popular_currencies,
        I18n.t("accounts.new.currency.all_others") => all_other_currencies
      }
    end

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
