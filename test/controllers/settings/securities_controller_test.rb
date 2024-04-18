require "test_helper"

class Settings::SecuritiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end
  test "get" do
    get settings_security_url
    assert_response :success
  end
end
