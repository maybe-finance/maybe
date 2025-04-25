module FormsHelper
  def styled_form_with(**options, &block)
    options[:builder] = StyledFormBuilder
    form_with(**options, &block)
  end

  def modal_form_wrapper(title:, subtitle: nil, overflow_visible: false, &block)
    content = capture &block

    render partial: "shared/modal_form", locals: { title:, subtitle:, content:, overflow_visible: }
  end

  def period_select(form:, selected:, classes: "border border-secondary bg-container-inset rounded-lg text-sm pr-7 cursor-pointer text-primary focus:outline-hidden focus:ring-0")
    periods_for_select = Period.all.map { |period| [ period.label_short, period.key ] }

    form.select(:period, periods_for_select, { selected: selected.key }, class: classes, data: { "auto-submit-form-target": "auto" })
  end

  def currencies_for_select
    Money::Currency.all_instances.sort_by { |currency| [ currency.priority, currency.name ] }
  end
end
