module LayoutHelper
  def menu_link_active_class(link_path)
    current_page?(link_path) ? "bg-white border-[#141414]/[0.07] text-gray-900 shadow-xs" : "border-transparent"
  end
end
