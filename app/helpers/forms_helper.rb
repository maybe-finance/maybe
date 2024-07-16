module FormsHelper
  def styled_form_with(**options, &block)
    options[:builder] = StyledFormBuilder
    form_with(**options, &block)
  end

  def form_field_tag(options = {}, &block)
    options[:class] = [ "form-field", options[:class] ].compact.join(" ")
    tag.div(**options, &block)
  end

  def radio_tab_tag(form:, name:, value:, label:, icon:, checked: false, disabled: false)
    form.label name, for: form.field_id(name, value), class: "group has-[:disabled]:cursor-not-allowed" do
      concat radio_tab_contents(label:, icon:)
      concat form.radio_button(name, value, checked:, disabled:, class: "hidden")
    end
  end

  def period_select(form:, selected:, classes: "border border-alpha-black-100 shadow-xs rounded-lg text-sm pr-7 cursor-pointer text-gray-900 focus:outline-none focus:ring-0")
    periods_for_select = [ [ "7D", "last_7_days" ], [ "1M", "last_30_days" ], [ "1Y", "last_365_days" ], [ "All", "all" ] ]
    form.select(:period, periods_for_select, { selected: selected }, class: classes, data: { "auto-submit-form-target": "auto" })
  end

  def money_with_currency_field(form, money_method, options = {})
    render partial: "shared/money_field", locals: {
      form: form,
      money_method: money_method,
      disable_currency: options[:disable_currency] || false,
      hide_currency: options[:hide_currency] || false,
      label: options[:label] || "Amount"
    }
  end

  def money_field(form, method, options = {})
    value = form.object.send(method)

    currency = value&.currency || Money::Currency.new(options[:default_currency] || "USD")

    # See "Monetizable" concern
    money_amount_method = method.to_s.chomp("_money").to_sym

    money_options = {
      value: value&.amount,
      placeholder: 100,
      min: -99999999999999,
      max: 99999999999999,
      step: currency.step
    }

    merged_options = options.merge(money_options)

    form.number_field money_amount_method, merged_options
  end

  def currency_select_full(form, method, options = {}, html_options = {}, &block)
    choices = currencies_for_select.map { |currency| [ "#{currency.name} (#{currency.iso_code})", currency.iso_code ] }
    form.select method, choices, options, html_options, &block
  end

  def currency_select(form, method, options = {}, html_options = {}, &block)
    choices = currencies_for_select.map(&:iso_code)
    form.select method, choices, options, html_options, &block
  end

  private

    def currencies_for_select
      Money::Currency.all_instances
                     .sort_by(&:priority)
    end

    def radio_tab_contents(label:, icon:)
      tag.div(class: "flex px-4 py-1 rounded-lg items-center space-x-2 justify-center text-gray-400 group-has-[:checked]:bg-white group-has-[:checked]:text-gray-800 group-has-[:checked]:shadow-sm") do
        concat lucide_icon(icon, class: "w-5 h-5")
        concat tag.span(label, class: "group-has-[:checked]:font-semibold")
      end
    end
end
