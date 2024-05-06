require "test_helper"

class Imports::StepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @import = imports(:completed_import)
  end

  test "should get load" do
    get load_import_url(@import)
    assert_response :success
  end

  test "should get configure" do
    get configure_import_url(@import)
    assert_response :success
  end

  test "should get clean" do
    get clean_import_url(@import)
    assert_response :success
  end

  test "should get confirm" do
    get confirm_import_url(@import)
    assert_response :success
  end
end
