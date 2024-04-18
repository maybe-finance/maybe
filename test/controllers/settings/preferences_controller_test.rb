require "test_helper"

class Settings::PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end
  test "get" do
    get settings_preferences_url
    assert_response :success
  end
end
