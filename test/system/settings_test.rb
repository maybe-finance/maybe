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

  test "can update self hosting settings" do
    Rails.application.config.app_mode.stubs(:self_hosted?).returns(true)
    open_settings_from_sidebar
    assert_selector "li", text: "Self hosting"
    click_link "Self hosting"
    assert_current_path settings_hosting_path
    assert_selector "h1", text: "Self-Hosting"
    check "setting_require_invite_for_signup", allow_label_click: true
    assert_selector "a", text: "Generate invite token"
    click_link "Generate invite token"
    assert_selector 'input[data-clipboard-target="source"]', visible: true, count: 1 # invite code copy widget
    copy_button = find('button[data-action="clipboard#copy"]', match: :first) # Find the first copy button (adjust if needed)
    copy_button.click
    assert_selector "span", text: "copied", visible: true
  end

  private

    def open_settings_from_sidebar
      find("#user-menu").click
      click_link "Settings"
    end
end
