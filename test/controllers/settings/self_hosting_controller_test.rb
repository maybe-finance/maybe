require "test_helper"

class Settings::SelfHostingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end
  test "should get edit" do
    get edit_settings_self_hosting_url
    assert_response :success
  end
end
