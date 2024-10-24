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

    delete session_url(@user.sessions.order(:created_at).last)
    assert_redirected_to new_session_path
    assert_equal "You have signed out successfully.", flash[:notice]
  end

  test "super admins can access the jobs page" do
    sign_in users(:maybe_support_staff)
    get good_job_url
    assert_redirected_to "http://www.example.com/good_job/jobs?locale=en"
  end

  test "non-super admins cannot access the jobs page" do
    get good_job_url
    assert_response :not_found
  end
end
