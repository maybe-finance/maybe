require "test_helper"

class LayoutHelperTest < ActionView::TestCase
  include LayoutHelper

  def test_menu_link_active_class
    # Mock the current_page? method to return true
    self.stub :current_page?, true do
      assert_equal "bg-white border-[#141414]/[0.07] text-gray-900 shadow-xs", menu_link_active_class("/test_path")
    end

    # Mock the current_page? method to return false
    self.stub :current_page?, false do
      assert_equal "", menu_link_active_class("/test_path")
    end
  end
end
