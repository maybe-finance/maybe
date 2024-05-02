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
      [ "Categories", "Categories", transactions_categories_path ],
      [ "Merchants", "Merchants", transactions_merchants_path ],
      [ "Rules", "Rules", transactions_rules_path ],
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

  test "all settings views and links are accessible" do
    open_settings_from_sidebar

    @settings_links.each_with_index do |(link_text, header_text, path), index|
      next_setting_path = @settings_links[index + 1][2] if index < @settings_links.size - 1
      prev_setting_path = @settings_links[index - 1][2] if index > 0

      find_link(link_text, exact: true).click

      assert_selector "h1", text: header_text
      assert_current_path path
      assert_link "Next", href: next_setting_path if next_setting_path.present?
      assert_link "Back", href: prev_setting_path if prev_setting_path.present?
    end

    # Conditional nav items don't show by default
    assert_no_text "Self-Hosting"
  end

  private
    def open_settings_from_sidebar
      find("#user-menu").click
      click_link "Settings"
    end
end
