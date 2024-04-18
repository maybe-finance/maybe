require "test_helper"

class Settings::NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end
  test "get" do
    get settings_notifications_url
    assert_response :success
  end
end
