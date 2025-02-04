require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "should get confirm" do
    user = users(:new_email)
    user.update!(unconfirmed_email: "new@example.com")
    token = user.generate_token_for(:email_confirmation)

    get new_email_confirmation_path(token: token)
    assert_redirected_to new_session_path
  end
end
