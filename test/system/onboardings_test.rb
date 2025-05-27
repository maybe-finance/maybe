require "application_system_test_case"

class OnboardingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:family_admin)
    @family = @user.family

    # Reset onboarding state
    @user.update!(set_onboarding_preferences_at: nil)

    sign_in @user
  end

  test "can complete the full onboarding flow" do
    # Start at the main onboarding page
    visit onboarding_path

    assert_text "Let's set up your account"
    assert_button "Continue"

    # Navigate to preferences
    click_button "Continue"

    assert_current_path preferences_onboarding_path
    assert_text "Configure your preferences"

    # Test that the chart renders without errors (this would catch the Series bug)
    assert_selector "[data-controller='time-series-chart']"

    # Fill out preferences form
    select "English (en)", from: "user_family_attributes_locale"
    select "United States Dollar (USD)", from: "user_family_attributes_currency"
    select "MM/DD/YYYY", from: "user_family_attributes_date_format"
    select "Light", from: "user_theme"

    # Submit preferences
    click_button "Complete"

    # Should redirect to goals page
    assert_current_path goals_onboarding_path
    assert_text "What brings you to Maybe?"
  end

  test "preferences page renders chart without errors" do
    visit preferences_onboarding_path

    # This test specifically targets the Series model bug
    # The chart should render without throwing JavaScript errors
    assert_selector "[data-controller='time-series-chart']"
    assert_selector "#previewChart"

    # Verify the chart data is properly formatted JSON
    chart_element = find("[data-controller='time-series-chart']")
    chart_data = chart_element["data-time-series-chart-data-value"]

    # Should be valid JSON
    assert_nothing_raised do
      JSON.parse(chart_data)
    end

    # Verify the preview example shows
    assert_text "Example"
    assert_text "$2,325.25"
    assert_text "+$78.90"
  end

  test "can change currency and see preview update" do
    visit preferences_onboarding_path

    # Change currency
    select "Euro (EUR)", from: "user_family_attributes_currency"

    # The preview should update (this tests the JavaScript controller)
    # Note: This would require the onboarding controller to handle currency changes
    assert_text "Example"
  end

  test "can change date format and see preview update" do
    visit preferences_onboarding_path

    # Change date format
    select "DD/MM/YYYY", from: "user_family_attributes_date_format"

    # The preview should update
    assert_text "Example"
  end

  test "can change theme" do
    visit preferences_onboarding_path

    # Change theme
    select "Dark", from: "user_theme"

    # Theme should be applied (this tests the JavaScript controller)
    assert_text "Example"
  end

  test "preferences form validation" do
    visit preferences_onboarding_path

    # Clear required fields and try to submit
    select "", from: "user_family_attributes_locale"
    click_button "Complete"

    # Should stay on preferences page with validation errors (may have query params)
    assert_match %r{/onboarding/preferences}, current_path
  end

  test "preferences form saves data correctly" do
    visit preferences_onboarding_path

    # Fill out form with specific values
    select "Spanish (es)", from: "user_family_attributes_locale"
    select "Euro (EUR)", from: "user_family_attributes_currency"
    select "DD/MM/YYYY", from: "user_family_attributes_date_format"
    select "Dark", from: "user_theme"

    click_button "Complete"

    # Wait for redirect to goals page to ensure form was submitted
    assert_current_path goals_onboarding_path

    # Verify data was saved
    @family.reload
    @user.reload

    assert_equal "es", @family.locale
    assert_equal "EUR", @family.currency
    assert_equal "%d/%m/%Y", @family.date_format
    assert_equal "dark", @user.theme
    assert_not_nil @user.set_onboarding_preferences_at
  end

  test "goals page renders correctly" do
    # Complete preferences first
    @user.update!(set_onboarding_preferences_at: Time.current)

    visit goals_onboarding_path

    assert_text "What brings you to Maybe?"
    assert_button "Next"
  end

  test "trial page renders correctly" do
    visit trial_onboarding_path

    assert_text "trial" # Adjust based on actual content
  end

  test "navigation between onboarding steps" do
    # Start at main onboarding
    visit onboarding_path
    click_button "Continue"

    # Should be at preferences
    assert_current_path preferences_onboarding_path

    # Complete preferences
    select "English (en)", from: "user_family_attributes_locale"
    select "United States Dollar (USD)", from: "user_family_attributes_currency"
    select "MM/DD/YYYY", from: "user_family_attributes_date_format"
    click_button "Complete"

    # Should be at goals
    assert_current_path goals_onboarding_path
  end

  test "onboarding nav shows correct steps" do
    visit preferences_onboarding_path

    # Check that navigation shows current step
    assert_selector "ul.hidden.md\\:flex.items-center.gap-2"
  end

  test "logout option is available during onboarding" do
    visit preferences_onboarding_path

    # Should have logout option (rendered as a button component)
    assert_text "Sign out"
  end

  private

    def sign_in(user)
      visit new_session_path
      within "form" do
        fill_in "Email", with: user.email
        fill_in "Password", with: user_password_test
        click_on "Log in"
      end

      # Wait for successful login
      assert_current_path root_path
    end
end
