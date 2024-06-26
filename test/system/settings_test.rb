require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    @settings_links = [
      [ "Account", "Account", settings_profile_path ],
      [ "Preferences", "Preferences", settings_preferences_path ],
      [ "Notifications", "Notifications", settings_notifications_path ],
      [ "Security", "Security", settings_security_path ],
      [ "Billing", "Billing", settings_billing_path ],
      [ "Accounts", "Accounts", accounts_path ],
      [ "Tags", "Tags", tags_path ],
      [ "Categories", "Categories", categories_path ],
      [ "Merchants", "Merchants", merchants_path ],
      [ "Rules", "Rules", account_transaction_rules_path ],
      [ "Imports", "Imports", imports_path ],
      [ "What's New", "What's New", changelog_path ],
      [ "Feedback", "Feedback", feedback_path ],
      [ "Invite friends", "Invite friends", invites_path ]
    ]
  end

  test "can access settings from sidebar" do
    open_settings_from_sidebar
    assert_selector "h1", text: "Account"
    assert_current_path settings_profile_path
  end

  private

    def open_settings_from_sidebar
      find("#user-menu").click
      click_link "Settings"
    end
end
