require "test_helper"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end
  test "get" do
    get settings_profile_url
    assert_response :success
  end
end
