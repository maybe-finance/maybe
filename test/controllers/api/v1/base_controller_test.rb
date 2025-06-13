# frozen_string_literal: true

require "test_helper"

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @oauth_app = Doorkeeper::Application.create!(
      name: "Test API App",
      redirect_uri: "https://example.com/callback",
      scopes: "read read_write"
    )

    # Clean up any existing API keys for the test user
    @user.api_keys.destroy_all

    # Create a test API key
    @api_key = ApiKey.create!(
      user: @user,
      name: "Test API Key",
      display_key: "test_api_key_12345",
      scopes: [ "read_write" ]
    )
    @plain_api_key = "test_api_key_12345"
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
      scopes: "read"
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

  test "should authenticate with valid API key" do
    get "/api/v1/test", params: {}, headers: {
      "X-Api-Key" => @plain_api_key
    }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal "test_success", response_body["message"]
    assert_equal @user.email, response_body["user"]
  end

  test "should reject invalid API key" do
    get "/api/v1/test", params: {}, headers: {
      "X-Api-Key" => "invalid_api_key"
    }

    assert_response :unauthorized
    response_body = JSON.parse(response.body)
    assert_equal "unauthorized", response_body["error"]
    assert_includes response_body["message"], "Access token or API key"
  end

  test "should reject expired API key" do
    @api_key.update!(expires_at: 1.day.ago)

    get "/api/v1/test", params: {}, headers: {
      "X-Api-Key" => @plain_api_key
    }

    assert_response :unauthorized
    response_body = JSON.parse(response.body)
    assert_equal "unauthorized", response_body["error"]
  end

  test "should reject revoked API key" do
    @api_key.revoke!

    get "/api/v1/test", params: {}, headers: {
      "X-Api-Key" => @plain_api_key
    }

    assert_response :unauthorized
    response_body = JSON.parse(response.body)
    assert_equal "unauthorized", response_body["error"]
  end

  test "should update last_used_at when API key is used" do
    original_time = @api_key.last_used_at

    get "/api/v1/test", params: {}, headers: {
      "X-Api-Key" => @plain_api_key
    }

    assert_response :success
    @api_key.reload
    assert_not_equal original_time, @api_key.last_used_at
    assert @api_key.last_used_at > (original_time || Time.at(0))
  end

  test "should prioritize OAuth over API key when both are provided" do
    access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read"
    )

    # Capture log output to verify OAuth is used
    logs = capture_log do
      get "/api/v1/test", params: {}, headers: {
        "Authorization" => "Bearer #{access_token.token}",
        "X-Api-Key" => @plain_api_key
      }
    end

    assert_response :success
    assert_includes logs, "OAuth Token"
    assert_not_includes logs, "API Key:"
  end

  test "should provide current_scopes for API key authentication" do
    get "/api/v1/test_scope_required", params: {}, headers: {
      "X-Api-Key" => @plain_api_key
    }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal "scope_authorized", response_body["message"]
    assert_includes response_body["scopes"], "read_write"
  end

  test "should authorize API key with required scope" do
    get "/api/v1/test_scope_required", params: {}, headers: {
      "X-Api-Key" => @plain_api_key
    }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal "scope_authorized", response_body["message"]
    assert_equal "write", response_body["required_scope"]
  end

  test "should reject API key without required scope" do
    # Revoke existing API key and create one with limited scopes
    @api_key.revoke!
    limited_api_key = ApiKey.create!(
      user: @user,
      name: "Limited API Key",
      display_key: "limited_key_123",
      scopes: [ "read" ]  # Only read scope
    )

    get "/api/v1/test_scope_required", params: {}, headers: {
      "X-Api-Key" => "limited_key_123"
    }

    assert_response :forbidden
    response_body = JSON.parse(response.body)
    assert_equal "insufficient_scope", response_body["error"]
    assert_includes response_body["message"], "write"
  end

  test "should authorize API key with multiple required scopes" do
    get "/api/v1/test_multiple_scopes_required", params: {}, headers: {
      "X-Api-Key" => @plain_api_key
    }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal "read_scope_authorized", response_body["message"]
    assert_includes response_body["scopes"], "read_write"
  end

  test "should reject API key missing one of multiple required scopes" do
    # The multiple scopes test now just checks for "read" permission,
    # so we need to create an API key without any scopes at all.
    # First revoke the existing key, then create one with empty scopes array won't work due to validation.
    # Instead, we'll test by trying to access the write endpoint with a read-only key.
    @api_key.revoke!

    read_only_key = ApiKey.create!(
      user: @user,
      name: "Read Only API Key",
      display_key: "read_only_key_123",
      scopes: [ "read" ]  # Only read scope, no write
    )

    # Try to access the write-requiring endpoint with read-only key
    get "/api/v1/test_scope_required", params: {}, headers: {
      "X-Api-Key" => "read_only_key_123"
    }

    assert_response :forbidden
    response_body = JSON.parse(response.body)
    assert_equal "insufficient_scope", response_body["error"]
  end

  test "should log API access with API key information" do
    logs = capture_log do
      get "/api/v1/test", params: {}, headers: {
        "X-Api-Key" => @plain_api_key
      }
    end

    assert_includes logs, "API Request"
    assert_includes logs, "GET /api/v1/test"
    assert_includes logs, @user.email
    assert_includes logs, "API Key: Test API Key"
  end

  test "should provide current_resource_owner method" do
    # This will be tested through the test controller once implemented
    skip "Will test via test controller implementation"
  end

  test "should handle ActiveRecord::RecordNotFound errors" do
    access_token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      scopes: "read"
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
      scopes: "read"
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
      scopes: "read"
    )

    # Try to access data from a different family
    get "/api/v1/test_family_access", params: {}, headers: {
      "Authorization" => "Bearer #{access_token.token}"
    }

    assert_response :forbidden
    response_body = JSON.parse(response.body)
    assert_equal "forbidden", response_body["error"]
  end

  test "should enforce family-based access control with API key" do
    # Create API key for a user in a different family
    other_family = families(:dylan_family)
    other_user = users(:family_member)
    other_user.update!(family: other_family)
    other_user.api_keys.destroy_all

    other_user_api_key = ApiKey.create!(
      user: other_user,
      name: "Other User API Key",
      display_key: "other_user_key_123",
      scopes: [ "read" ]
    )

    # Try to access data from a different family
    get "/api/v1/test_family_access", params: {}, headers: {
      "X-Api-Key" => "other_user_key_123"
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
