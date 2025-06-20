# frozen_string_literal: true

require "test_helper"

class OauthMobileTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:empty)
    sign_in(@user)

    @oauth_app = Doorkeeper::Application.create!(
      name: "Maybe Mobile App",
      redirect_uri: "maybeapp://oauth/callback",
      scopes: "read"
    )
  end

  test "mobile oauth authorization with custom scheme redirect" do
    get "/oauth/authorize", params: {
      client_id: @oauth_app.uid,
      redirect_uri: @oauth_app.redirect_uri,
      response_type: "code",
      scope: "read",
      display: "mobile"
    }

    assert_response :success

    # Check that Turbo is disabled in the form
    assert_match(/data-turbo="false"/, response.body)
    assert_match(/maybeapp:\/\/oauth\/callback/, response.body)
  end

  test "mobile oauth detects custom scheme in redirect_uri" do
    get "/oauth/authorize", params: {
      client_id: @oauth_app.uid,
      redirect_uri: "maybeapp://oauth/callback",
      response_type: "code",
      scope: "read"
    }

    assert_response :success

    # Should detect mobile flow from redirect_uri
    assert_match(/data-turbo="false"/, response.body)
  end

  test "mobile oauth authorization flow completes successfully" do
    post "/oauth/authorize", params: {
      client_id: @oauth_app.uid,
      redirect_uri: @oauth_app.redirect_uri,
      response_type: "code",
      scope: "read",
      display: "mobile"
    }

    # Should redirect to the custom scheme
    assert_response :redirect
    assert response.location.start_with?("maybeapp://oauth/callback")
  end

  test "mobile oauth preserves display parameter through forms" do
    get "/oauth/authorize", params: {
      client_id: @oauth_app.uid,
      redirect_uri: @oauth_app.redirect_uri,
      response_type: "code",
      scope: "read",
      display: "mobile"
    }

    assert_response :success

    # Check that display parameter is preserved in hidden fields
    assert_match(/<input[^>]*name="display"[^>]*value="mobile"/, response.body)
  end
end
