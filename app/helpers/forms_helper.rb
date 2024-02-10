module FormsHelper
  def form_field_tag(&)
    tag.div class: "form-field", &
  end
end
