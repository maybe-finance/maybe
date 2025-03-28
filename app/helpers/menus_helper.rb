module MenusHelper
  def contextual_menu(icon: "more-horizontal", id: nil, &block)
    tag.div id: id, data: { controller: "menu" } do
      concat contextual_menu_icon(icon)
      concat contextual_menu_content(&block)
    end
  end

  def contextual_menu_modal_action_item(label, url, icon: "pencil-line", turbo_frame: :modal)
    link_to url, class: "flex items-center rounded-md text-primary hover:bg-container-hover p-2 gap-2", data: { action: "click->menu#close", turbo_frame: turbo_frame } do
      concat(lucide_icon(icon, class: "shrink-0 w-5 h-5 text-secondary"))
      concat(tag.span(label, class: "text-sm"))
    end
  end

  def contextual_menu_item(label, url:, icon:, turbo_frame: nil)
    link_to url, class: "flex items-center rounded-md text-primary hover:bg-container-hover p-2 gap-2", data: { action: "click->menu#close", turbo_frame: turbo_frame } do
      concat(lucide_icon(icon, class: "shrink-0 w-5 h-5 text-secondary"))
      concat(tag.span(label, class: "text-sm"))
    end
  end

  def contextual_menu_destructive_item(label, url, turbo_confirm: true, turbo_frame: nil)
    button_to url,
              method: :delete,
              class: "flex items-center w-full rounded-md text-red-500 hover:bg-red-500/5 p-2 gap-2",
              data: { turbo_confirm: turbo_confirm, turbo_frame: } do
      concat(lucide_icon("trash-2", class: "shrink-0 w-5 h-5"))
      concat(tag.span(label, class: "text-sm"))
    end
  end

  private
    def contextual_menu_icon(icon)
      tag.button class: "w-9 h-9 flex justify-center items-center hover:bg-surface-hover rounded-lg cursor-pointer focus:outline-none focus-visible:outline-none", data: { menu_target: "button" } do
        lucide_icon icon, class: "w-5 h-5 text-secondary"
      end
    end

    def contextual_menu_content(&block)
      tag.div class: "min-w-[200px] p-1 z-50 shadow-border-xs bg-white rounded-lg hidden",
               data: { menu_target: "content" } do
        capture(&block)
      end
    end
end
