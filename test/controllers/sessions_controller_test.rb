require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
  end

  test "can sign in" do
    post session_url, params: { email: @user.email, password: "password" }
    assert_redirected_to root_url
  end

  test "sets last_login_at on successful login" do
    assert_changes -> { @user.reload.last_login_at }, from: nil do
      post session_url, params: { email: @user.email, password: "password" }
    end
  end
end
