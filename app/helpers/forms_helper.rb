module FormsHelper
  def form_field_tag(&)
    tag.div class: "form-field", &
  end

  def currency_dropdown(f: nil, options: [])
    render partial: "shared/currency_dropdown", locals: { f: f, options: options }
  end
end
