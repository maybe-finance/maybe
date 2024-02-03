require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_url
    assert_response :success
  end

  test "create" do
    post registration_url, params: { user: {
      email: "john@example.com",
      password: "password",
      password_confirmation: "password" } }

    assert_redirected_to root_url
  end

  test "create when hosted requires an invitation code" do
    ENV["HOSTED"] = "true"

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
  ensure
    ENV["HOSTED"] = nil
  end
end
