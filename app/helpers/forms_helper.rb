module FormsHelper
  def form_field_tag(&block)
    content = capture(&block)
    tag.div content, class: "form-field"
  end
end
