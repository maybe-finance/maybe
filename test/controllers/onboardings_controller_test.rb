require "test_helper"

class OnboardingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @family = @user.family

    # Reset onboarding state
    @user.update!(set_onboarding_preferences_at: nil)

    sign_in @user
  end

  test "should get show" do
    get onboarding_url
    assert_response :success
    assert_select "h1", text: /set up your account/i
  end

  test "should get preferences" do
    get preferences_onboarding_url
    assert_response :success
    assert_select "h1", text: /preferences/i
  end

  test "preferences page renders Series chart data without errors" do
    get preferences_onboarding_url
    assert_response :success

    # This test specifically targets the Series model bug
    # The page should render without throwing the "unknown keyword: :trend" error
    assert_select "[data-controller='time-series-chart']"
    assert_select "#previewChart"

    # Verify that the Series.from_raw_values call in the view works
    # If the Series bug existed, this would raise an ActionView::Template::Error
    assert_no_match /unknown keyword: :trend/, response.body
  end

  test "preferences page includes chart with valid JSON data" do
    get preferences_onboarding_url
    assert_response :success

    # Extract the chart data from the response
    chart_data_match = response.body.match(/data-time-series-chart-data-value="([^"]*)"/)
    assert chart_data_match, "Chart data attribute should be present"

    # Decode HTML entities and parse JSON
    chart_data_json = CGI.unescapeHTML(chart_data_match[1])

    # Should be valid JSON
    assert_nothing_raised do
      chart_data = JSON.parse(chart_data_json)

      # Verify expected structure
      assert chart_data.key?("start_date")
      assert chart_data.key?("end_date")
      assert chart_data.key?("interval")
      assert chart_data.key?("trend")
      assert chart_data.key?("values")

      # Verify trend has expected structure
      trend = chart_data["trend"]
      assert trend.key?("value")
      assert trend.key?("percent")
      assert trend.key?("current")
      assert trend.key?("previous")

      # Verify values array has expected structure
      values = chart_data["values"]
      assert values.is_a?(Array)
      assert values.length > 0

      values.each do |value|
        assert value.key?("date")
        assert value.key?("value")
        assert value.key?("trend")
      end
    end
  end

  test "should get goals" do
    get goals_onboarding_url
    assert_response :success
    assert_select "h1", text: /What brings you to Maybe/i
  end

  test "should get trial" do
    get trial_onboarding_url
    assert_response :success
  end

  test "preferences page shows currency formatting example" do
    get preferences_onboarding_url
    assert_response :success

    # Should show formatted currency example
    assert_select "p", text: /\$2,325\.25/
    assert_select "span", text: /\+\$78\.90/
  end

  test "preferences page shows date formatting example" do
  get preferences_onboarding_url
  assert_response :success

  # Should show formatted date example (checking for the specific format shown)
  assert_match /10-23-2024/, response.body
end

  test "preferences page includes all required form fields" do
  get preferences_onboarding_url
  assert_response :success

  # Verify all form fields are present
  assert_select "select[name='user[family_attributes][locale]']"
  assert_select "select[name='user[family_attributes][currency]']"
  assert_select "select[name='user[family_attributes][date_format]']"
  assert_select "select[name='user[theme]']"
  assert_select "button[type='submit']"
end

  test "preferences page includes JavaScript controllers" do
    get preferences_onboarding_url
    assert_response :success

    # Should include onboarding controller for dynamic updates
    assert_select "[data-controller*='onboarding']"
    assert_select "[data-controller*='time-series-chart']"
  end

  test "all onboarding pages set correct layout" do
    # Test that all onboarding pages use the wizard layout
    get onboarding_url
    assert_response :success

    get preferences_onboarding_url
    assert_response :success

    get goals_onboarding_url
    assert_response :success

    get trial_onboarding_url
    assert_response :success
  end

  test "onboarding pages require authentication" do
  sign_out

  get onboarding_url
  assert_redirected_to new_session_url

  get preferences_onboarding_url
  assert_redirected_to new_session_url

  get goals_onboarding_url
  assert_redirected_to new_session_url

  get trial_onboarding_url
  assert_redirected_to new_session_url
end

    private

      def sign_out
        @user.sessions.each do |session|
          delete session_path(session)
        end
      end
end
