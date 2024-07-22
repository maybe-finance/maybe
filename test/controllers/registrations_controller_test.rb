require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_url
    assert_response :success
  end

  test "create redirects to correct URL" do
    post registration_url, params: { user: {
      email: "john@example.com",
      password: "password",
      password_confirmation: "password" } }

    assert_redirected_to root_url
  end

  test "create seeds default transaction categories" do
    assert_difference "Category.count", Category::DEFAULT_CATEGORIES.size do
      post registration_url, params: { user: {
      email: "john@example.com",
      password: "password",
      password_confirmation: "password" } }
    end
  end

  test "sets last_login_at on successful registration" do
    post registration_url, params: { user: {
      email: "john@example.com",
      password: "password",
      password_confirmation: "password" } }
    assert_not_nil User.find_by(email: "john@example.com").last_login_at
  end

  test "create when hosted requires an invite code" do
    with_env_overrides REQUIRE_INVITE_CODE: "true" do
      assert_no_difference "User.count" do
        post registration_url, params: { user: {
          email: "john@example.com",
          password: "password",
          password_confirmation: "password" } }
        assert_redirected_to new_registration_url

        post registration_url, params: { user: {
          email: "john@example.com",
          password: "password",
          password_confirmation: "password",
          invite_code: "foo" } }
        assert_redirected_to new_registration_url
      end

      assert_difference "User.count", +1 do
        post registration_url, params: { user: {
          email: "john@example.com",
          password: "password",
          password_confirmation: "password",
          invite_code: InviteCode.generate! } }
        assert_redirected_to root_url
      end
    end
  end
end
