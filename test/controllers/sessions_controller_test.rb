require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
  end

  test "login page" do
    get new_session_url
    assert_response :success
  end

  test "can sign in" do
    sign_in @user
    assert_redirected_to root_url
    assert Session.exists?(user_id: @user.id)

    get root_url
    assert_response :success
  end

  test "fails to sign in with bad password" do
    post sessions_url, params: { email: @user.email, password: "bad" }
    assert_response :unprocessable_entity
    assert_equal "Invalid email or password.", flash[:alert]
  end

  test "can sign out" do
    sign_in @user
    session_record = @user.sessions.last

    delete session_url(session_record)
    assert_redirected_to new_session_path
    assert_equal "You have signed out successfully.", flash[:notice]

    # Verify session is destroyed
    assert_nil Session.find_by(id: session_record.id)
  end

  test "redirects to MFA verification when MFA enabled" do
    @user.setup_mfa!
    @user.enable_mfa!
    @user.sessions.destroy_all # Clean up any existing sessions

    post sessions_path, params: { email: @user.email, password: user_password_test }

    assert_redirected_to verify_mfa_path
    assert_equal @user.id, session[:mfa_user_id]
    assert_not Session.exists?(user_id: @user.id)
  end
end
