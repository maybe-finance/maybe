module MenusHelper
  def contextual_menu(&block)
    tag.div data: { controller: "menu" } do
      concat contextual_menu_icon
      concat contextual_menu_content(&block)
    end
  end

  def contextual_menu_modal_action_item(label, url, icon: "pencil-line", turbo_frame: :modal)
    link_to url, class: "flex items-center rounded-lg text-primary hover:bg-gray-50 py-2 px-3 gap-2", data: { turbo_frame: } do
      concat(lucide_icon(icon, class: "shrink-0 w-5 h-5 text-secondary"))
      concat(tag.span(label, class: "text-sm"))
    end
  end

  def contextual_menu_destructive_item(label, url, turbo_confirm: true, turbo_frame: nil)
    button_to url,
              method: :delete,
              class: "flex items-center w-full rounded-lg text-red-500 hover:bg-red-500/5 py-2 px-3 gap-2",
              data: { turbo_confirm: turbo_confirm, turbo_frame: } do
      concat(lucide_icon("trash-2", class: "shrink-0 w-5 h-5"))
      concat(tag.span(label, class: "text-sm"))
    end
  end

  private
    def contextual_menu_icon
      tag.button class: "flex hover:bg-gray-100 p-2 rounded cursor-pointer", data: { menu_target: "button" } do
        lucide_icon "more-horizontal", class: "w-5 h-5 text-secondary"
      end
    end

    def contextual_menu_content(&block)
      tag.div class: "z-50 border border-alpha-black-25 bg-white rounded-lg shadow-xs hidden",
               data: { menu_target: "content" } do
        capture(&block)
      end
    end
end
