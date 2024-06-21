module MenusHelper
  def contextual_menu(&block)
    tag.div class: "relative cursor-pointer", data: { controller: "menu" } do
      concat contextual_menu_icon
      concat contextual_menu_content(&block)
    end
  end

  def contextual_menu_modal_action_item(label, url, icon: "pencil-line")
    link_to url, class: "flex items-center rounded-lg text-gray-900 hover:bg-gray-50 py-2 px-3 gap-2" do
      concat(lucide_icon(icon, class: "shrink-0 w-5 h-5 text-gray-500"))
      concat(tag.span(label, class: "text-sm"))
    end
  end

  def contextual_menu_destructive_item(label, url, confirm_title:, confirm_body:, confirm_accept:)
    link_to url,
            class: "flex items-center rounded-lg text-red-500 hover:bg-red-500/5 py-2 px-3 gap-2",
            data: { turbo_confirm: { confirm_title:, confirm_body:, confirm_accept: } } do
      concat(lucide_icon("trash-2", class: "shrink-0 w-5 h-5"))
      concat(tag.span(label, class: "text-sm"))
    end
  end

  private
    def contextual_menu_icon
      tag.button class: "flex hover:bg-gray-100 p-2 rounded", data: { menu_target: "button" } do
        lucide_icon "more-horizontal", class: "w-5 h-5 text-gray-500"
      end
    end

    def contextual_menu_content(&block)
      tag.div class: "absolute z-10 top-10 right-0 border border-alpha-black-25 bg-white rounded-lg shadow-xs hidden", data: { menu_target: "content" } do
        capture(&block)
      end
    end
end
