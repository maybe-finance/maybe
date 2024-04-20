module FormsHelper
  def form_field_tag(options = {}, &block)
    options[:class] = [ "form-field", options[:class] ].compact.join(" ")
    tag.div **options, &block
  end

  def radio_tab_tag(form:, name:, value:, label:, icon:, checked: false, disabled: false)
    form.label name, for: form.field_id(name, value), class: "group has-[:disabled]:cursor-not-allowed" do
      concat radio_tab_contents(label:, icon:)
      concat form.radio_button(name, value, checked:, disabled:, class: "hidden")
    end
  end

  private
    def radio_tab_contents(label:, icon:)
      tag.div(class: "flex px-4 py-1 rounded-lg items-center space-x-2 justify-center text-gray-400 group-has-[:checked]:bg-white group-has-[:checked]:text-gray-800 group-has-[:checked]:shadow-sm") do
        concat lucide_icon(icon, class: "w-5 h-5")
        concat tag.span(label, class: "group-has-[:checked]:font-semibold")
      end
    end
end
