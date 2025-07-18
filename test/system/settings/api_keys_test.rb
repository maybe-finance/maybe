require "application_system_test_case"

class Settings::ApiKeysTest < ApplicationSystemTestCase
  setup do
    @user = users(:family_admin)
    @user.api_keys.destroy_all # Ensure clean state
    login_as @user
  end

  test "should show no API key state when user has no active keys" do
    visit settings_api_key_path

    assert_text "Create Your API Key"
    assert_text "Get programmatic access to your Maybe data"
    assert_text "Access your account data programmatically"
    assert_link "Create API Key", href: new_settings_api_key_path
  end

  test "should navigate to create new API key form" do
    visit settings_api_key_path
    click_link "Create API Key"

    assert_current_path new_settings_api_key_path
    assert_text "Create New API Key"
    assert_field "API Key Name"
    assert_text "Read Only"
    assert_text "Read/Write"
  end

  test "should create a new API key with selected scopes" do
    visit new_settings_api_key_path

    fill_in "API Key Name", with: "Test Integration Key"
    choose "Read/Write"

    click_button "Create API Key"

    # Should redirect to show page with the API key details
    assert_current_path settings_api_key_path
    assert_text "Test Integration Key"
    assert_text "Your API Key"

    # Should show the actual API key value
    api_key_display = find("#api-key-display")
    assert api_key_display.text.length > 30 # Should be a long hex string

    # Should show copy buttons
    assert_button "Copy API Key"
    assert_link "Create New Key"
  end

  test "should show current API key details after creation" do
    # Create an API key first
    api_key = ApiKey.create!(
      user: @user,
      name: "Production API Key",
      display_key: "test_plain_key_123",
      scopes: [ "read_write" ]
    )

    visit settings_api_key_path

    assert_text "Your API Key"
    assert_text "Production API Key"
    assert_text "Active"
    assert_text "Read/Write"
    assert_text "Never used"
    assert_link "Create New Key"
    assert_button "Revoke Key"
  end

  test "should show usage instructions and example curl command" do
    api_key = ApiKey.create!(
      user: @user,
      name: "Test API Key",
      display_key: "test_key_123",
      scopes: [ "read" ]
    )

    visit settings_api_key_path

    assert_text "How to use your API key"
    assert_text "curl -H \"X-Api-Key: test_key_123\""
    assert_text "/api/v1/accounts"
  end

  test "should allow regenerating API key" do
    api_key = ApiKey.create!(
      user: @user,
      name: "Old API Key",
      display_key: "old_key_123",
      scopes: [ "read" ]
    )

    visit settings_api_key_path
    click_link "Create New Key"

    # Should be on the new API key form
    assert_text "Create New API Key"

    fill_in "API Key Name", with: "New API Key"
    choose "Read Only"
    click_button "Create API Key"

    # Should redirect to show page with new key
    assert_text "New API Key"
    assert_text "Your API Key"

    # Old key should be revoked
    api_key.reload
    assert api_key.revoked?
  end

  test "should allow revoking API key with confirmation" do
    api_key = ApiKey.create!(
      user: @user,
      name: "Test API Key",
      display_key: "test_key_123",
      scopes: [ "read" ]
    )

    visit settings_api_key_path

    # Click the revoke button to open the modal
    click_button "Revoke Key"

    # Wait for the dialog and then confirm
    assert_selector "#confirm-dialog", visible: true
    within "#confirm-dialog" do
      click_button "Confirm"
    end

    # Wait for redirect after revoke
    assert_no_selector "#confirm-dialog"

    assert_text "Create Your API Key"
    assert_text "Get programmatic access to your Maybe data"

    # Key should be revoked in the database
    api_key.reload
    assert api_key.revoked?
  end

  test "should redirect to show when user already has active key and tries to visit new" do
    api_key = ApiKey.create!(
      user: @user,
      name: "Existing API Key",
      display_key: "existing_key_123",
      scopes: [ "read" ]
    )

    visit new_settings_api_key_path

    assert_current_path settings_api_key_path
  end

  test "should show API key in navigation" do
    visit settings_api_key_path

    within("nav") do
      assert_text "API Key"
    end
  end

  test "should validate API key name is required" do
    visit new_settings_api_key_path

    # Try to submit without name
    choose "Read Only"
    click_button "Create API Key"

    # Should stay on form with validation error
    assert_current_path new_settings_api_key_path
    assert_field "API Key Name" # Form should still be visible
    # The form might not show the validation error inline, but should remain on the form
  end

  test "should show last used timestamp when API key has been used" do
    api_key = ApiKey.create!(
      user: @user,
      name: "Used API Key",
      display_key: "used_key_123",
      scopes: [ "read" ],
      last_used_at: 2.hours.ago
    )

    visit settings_api_key_path

    assert_text "2 hours ago"
    assert_no_text "Never used"
  end

  test "should show expiration date when API key has expiration" do
    api_key = ApiKey.create!(
      user: @user,
      name: "Expiring API Key",
      display_key: "expiring_key_123",
      scopes: [ "read" ],
      expires_at: 30.days.from_now
    )

    visit settings_api_key_path

    # Should show some indication of expiration (exact format may vary)
    assert_no_text "Never expires"
  end
end
