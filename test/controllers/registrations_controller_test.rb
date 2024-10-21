require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  EMAIL="john@example.com".freeze
  PASSWORD="password".freeze
  test "new" do
    get new_registration_url
    assert_response :success
  end

  test "create redirects to correct URL" do
    post registration_url, params: { user: {
      email: EMAIL,
      password: PASSWORD,
      password_confirmation: PASSWORD } }

    assert_redirected_to root_url
  end

  test "create seeds default transaction categories" do
    assert_difference "Category.count", Category::DEFAULT_CATEGORIES.size do
      post registration_url, params: { user: {
      email: EMAIL,
      password: PASSWORD,
      password_confirmation: PASSWORD } }
    end
  end

  test "create when hosted requires an invite code" do
    with_env_overrides REQUIRE_INVITE_CODE: "true" do
      assert_no_difference "User.count" do
        post registration_url, params: { user: {
          email: EMAIL,
          password: PASSWORD,
          password_confirmation: PASSWORD } }
        assert_redirected_to new_registration_url

        post registration_url, params: { user: {
          email: EMAIL,
          password: PASSWORD,
          password_confirmation: PASSWORD,
          invite_code: "foo" } }
        assert_redirected_to new_registration_url
      end

      assert_difference "User.count", +1 do
        post registration_url, params: { user: {
          email: EMAIL,
          password: PASSWORD,
          password_confirmation: PASSWORD,
          invite_code: InviteCode.generate! } }
        assert_redirected_to root_url
      end
    end
  end
end
