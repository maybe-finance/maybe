class MaybeFormBuilder < TailwindFormBuilder
  TEXT_LIKE_FIELDS = field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]

  has_styles_for :field_wrapper, "relative border border-gray-100 bg-offwhite rounded-xl focus-within:bg-white focus-within:shadow focus-within:opacity-100"
  has_styles_for TEXT_LIKE_FIELDS, "p-4 pt-1 bg-transparent border-none opacity-50 focus:outline-none focus:ring-0 focus-within:opacity-100 w-full"
  has_styles_for :label, "p-4 pb-0 block text-sm font-medium text-gray-700"
  has_styles_for :submit, "flex justify-center px-4 py-3 text-sm font-medium text-white bg-black rounded-xl hover:bg-black focus:outline-none focus:ring-2 focus:ring-gray-200 shadow"

  def field_wrapper(&block)
    @template.content_tag(:div, { class: self.class.styles_for[:field_wrapper] }) do
      block.call
    end
  end
end
