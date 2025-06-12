# frozen_string_literal: true

require "test_helper"

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @oauth_app = Doorkeeper::Application.create!(
      name: "Test API App",
      redirect_uri: "https://example.com/callback",
      scopes: "read_accounts"
    )
  end

  test "should require authentication" do
    # Test that endpoints require OAuth tokens
    get "/api/v1/test"
    assert_response :unauthorized

    response_body = JSON.parse(response.body)
    assert_equal "unauthorized", response_body["error"]
  end

    test "should authenticate with valid access token" do
    # Create a valid access token
    access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read_accounts"
    )

    get "/api/v1/test", params: {}, headers: {
      "Authorization" => "Bearer #{access_token.token}"
    }

    # Should not be unauthorized when token is valid
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal "test_success", response_body["message"]
    assert_equal @user.email, response_body["user"]
  end

    test "should reject invalid access token" do
    get "/api/v1/test", params: {}, headers: {
      "Authorization" => "Bearer invalid_token"
    }

    assert_response :unauthorized
    response_body = JSON.parse(response.body)
    assert_equal "unauthorized", response_body["error"]
  end

  test "should provide current_resource_owner method" do
    # This will be tested through the test controller once implemented
    skip "Will test via test controller implementation"
  end

    test "should handle ActiveRecord::RecordNotFound errors" do
    access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read_accounts"
    )

    # This will trigger a not found error in the test controller
    get "/api/v1/test_not_found", params: {}, headers: {
      "Authorization" => "Bearer #{access_token.token}"
    }

    assert_response :not_found
    response_body = JSON.parse(response.body)
    assert_equal "record_not_found", response_body["error"]
  end

    test "should log API access" do
    access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read_accounts"
    )

    # Capture log output
    logs = capture_log do
      get "/api/v1/test", params: {}, headers: {
        "Authorization" => "Bearer #{access_token.token}"
      }
    end

    assert_includes logs, "API Request"
    assert_includes logs, "GET /api/v1/test"
    assert_includes logs, @user.email
  end

    test "should enforce family-based access control" do
    # Create another family user
    other_family = families(:dylan_family)
    other_user = users(:family_member)
    other_user.update!(family: other_family)

    access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: other_user.id,
      scopes: "read_accounts"
    )

    # Try to access data from a different family
    get "/api/v1/test_family_access", params: {}, headers: {
      "Authorization" => "Bearer #{access_token.token}"
    }

    assert_response :forbidden
    response_body = JSON.parse(response.body)
    assert_equal "forbidden", response_body["error"]
  end

  private

  def capture_log(&block)
    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(io)

    yield

    io.string
  ensure
    Rails.logger = original_logger
  end
end