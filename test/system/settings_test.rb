require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    @settings_links = [
      [ "Account", settings_profile_path ],
      [ "Preferences", settings_preferences_path ],
      [ "Accounts", accounts_path ],
      [ "Tags", tags_path ],
      [ "Categories", categories_path ],
      [ "Merchants", merchants_path ],
      [ "Imports", imports_path ],
      [ "What's new", changelog_path ],
      [ "Feedback", feedback_path ]
    ]
  end

  test "can access settings from sidebar" do
    open_settings_from_sidebar
    assert_selector "h1", text: "Account"
    assert_current_path settings_profile_path

    @settings_links.each do |name, path|
      click_link name
      assert_selector "h1", text: name
      assert_current_path path
    end
  end

  private

    def open_settings_from_sidebar
      find("#user-menu").click
      click_link "Settings"
    end
end
