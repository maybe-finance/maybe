require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "should get confirm" do
    get email_confirmations_confirm_url
    assert_response :success
  end
end
