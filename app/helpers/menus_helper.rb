module MenusHelper
  def contextual_menu(&block)
    tag.div class: "relative cursor-pointer", data: { controller: "menu" } do
      concat contextual_menu_icon
      concat contextual_menu_content(&block)
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
