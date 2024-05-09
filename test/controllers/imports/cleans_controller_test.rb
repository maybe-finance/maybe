require "test_helper"

class Imports::CleansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "should get show" do
    import = imports(:completed_import)

    get import_clean_url(import)
    assert_response :success
  end
end
