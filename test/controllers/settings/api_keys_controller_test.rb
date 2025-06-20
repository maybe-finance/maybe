require "test_helper"

class Settings::ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.api_keys.destroy_all # Ensure clean state
    sign_in @user
  end

  test "should show no API key page when user has no active keys" do
    get settings_api_key_path
    assert_response :success
  end

  test "should show current API key when user has active key" do
    @api_key = ApiKey.create!(
      user: @user,
      name: "Test API Key",
      display_key: "test_key_123",
      scopes: [ "read" ]
    )

    get settings_api_key_path
    assert_response :success
  end

  test "should show new API key form" do
    get new_settings_api_key_path
    assert_response :success
  end

  test "should redirect to show when user already has active key and tries to visit new" do
    ApiKey.create!(
      user: @user,
      name: "Existing API Key",
      display_key: "existing_key_123",
      scopes: [ "read" ]
    )

    get new_settings_api_key_path
    assert_redirected_to settings_api_key_path
  end

  test "should create new API key with valid parameters" do
    assert_difference "ApiKey.count", 1 do
      post settings_api_key_path, params: {
        api_key: {
          name: "Test Integration Key",
          scopes: "read_write"
        }
      }
    end

    assert_redirected_to settings_api_key_path
    follow_redirect!
    assert_response :success

    api_key = @user.api_keys.active.first
    assert_equal "Test Integration Key", api_key.name
    assert_includes api_key.scopes, "read_write"
  end

  test "should revoke existing key when creating new one" do
    old_key = ApiKey.create!(
      user: @user,
      name: "Old API Key",
      display_key: "old_key_123",
      scopes: [ "read" ]
    )

    post settings_api_key_path, params: {
      api_key: {
        name: "New API Key",
        scopes: "read_write"
      }
    }

    assert_redirected_to settings_api_key_path
    follow_redirect!
    assert_response :success

    old_key.reload
    assert old_key.revoked?

    new_key = @user.api_keys.active.first
    assert_equal "New API Key", new_key.name
  end

  test "should not create API key without name" do
    assert_no_difference "ApiKey.count" do
      post settings_api_key_path, params: {
        api_key: {
          name: "",
          scopes: "read"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create API key without scopes" do
  # Ensure clean state for this specific test
  @user.api_keys.destroy_all
  initial_user_count = @user.api_keys.count

  assert_no_difference "@user.api_keys.count" do
    post settings_api_key_path, params: {
      api_key: {
        name: "Test Key",
        scopes: []
      }
    }
  end

  assert_response :unprocessable_entity
  assert_equal initial_user_count, @user.api_keys.reload.count
end

  test "should revoke API key" do
    @api_key = ApiKey.create!(
      user: @user,
      name: "Test API Key",
      display_key: "test_key_123",
      scopes: [ "read" ]
    )

    delete settings_api_key_path

    assert_redirected_to settings_api_key_path
    follow_redirect!
    assert_response :success

    @api_key.reload
    assert @api_key.revoked?
  end

  test "should handle revoke when no API key exists" do
    delete settings_api_key_path

    assert_redirected_to settings_api_key_path
    # Should not error even when no API key exists
  end

  test "should only allow one active API key per user" do
    # Create first API key
    post settings_api_key_path, params: {
      api_key: {
        name: "First Key",
        scopes: "read"
      }
    }

    first_key = @user.api_keys.active.first

    # Create second API key
    post settings_api_key_path, params: {
      api_key: {
        name: "Second Key",
        scopes: "read_write"
      }
    }

    # First key should be revoked
    first_key.reload
    assert first_key.revoked?

    # Only one active key should exist
    assert_equal 1, @user.api_keys.active.count
    assert_equal "Second Key", @user.api_keys.active.first.name
  end

  test "should generate secure random API key" do
    post settings_api_key_path, params: {
      api_key: {
        name: "Random Key Test",
        scopes: "read"
      }
    }

    assert_redirected_to settings_api_key_path
    follow_redirect!
    assert_response :success

    # Verify the API key was created with expected properties
    api_key = @user.api_keys.active.first
    assert api_key.present?
    assert_equal "Random Key Test", api_key.name
    assert_includes api_key.scopes, "read"
  end
end
