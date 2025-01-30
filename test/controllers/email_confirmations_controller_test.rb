require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "should get confirm" do
    user = users(:new_email)
    user.update!(unconfirmed_email: "new@example.com", email_confirmation_sent_at: Time.current)
    token = user.generate_token_for(:email_confirmation)
    
    get confirm_email_email_confirmations_path(token: token)
    assert_redirected_to new_session_path
  end
end
