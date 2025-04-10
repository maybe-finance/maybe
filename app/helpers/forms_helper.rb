module FormsHelper
  def styled_form_with(**options, &block)
    options[:builder] = StyledFormBuilder
    form_with(**options, &block)
  end

  def modal_form_wrapper(title:, subtitle: nil, &block)
    content = capture &block

    render partial: "shared/modal_form", locals: { title:, subtitle:, content: }
  end

  def radio_tab_tag(form:, name:, value:, label:, icon:, checked: false, disabled: false)
    form.label name, for: form.field_id(name, value), class: "group has-disabled:cursor-not-allowed" do
      concat radio_tab_contents(label:, icon:)
      concat form.radio_button(name, value, checked:, disabled:, class: "hidden")
    end
  end

  def period_select(form:, selected:, classes: "border border-secondary rounded-lg text-sm pr-7 cursor-pointer text-primary focus:outline-hidden focus:ring-0")
    periods_for_select = Period.all.map { |period| [ period.label_short, period.key ] }

    form.select(:period, periods_for_select, { selected: selected.key }, class: classes, data: { "auto-submit-form-target": "auto" })
end


  def currencies_for_select
    Money::Currency.all_instances.sort_by { |currency| [ currency.priority, currency.name ] }
  end

  private
    def radio_tab_contents(label:, icon:)
      tag.div(class: "flex px-4 py-1 rounded-lg items-center space-x-2 justify-center text-subdued group-has-checked:bg-container group-has-checked:text-gray-800 group-has-checked:shadow-sm") do
        concat lucide_icon(icon, class: "w-5 h-5")
        concat tag.span(label, class: "group-has-checked:font-semibold")
      end
    end
end
