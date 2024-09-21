require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do 
    sign_in @user = users(:family_admin)
  end

  test "gets index" do 
    get imports_url 

    assert_response :success

    @user.family.imports.ordered.each do |import|
      assert_select "#" + dom_id(import), count: 1
    end
  end
end
