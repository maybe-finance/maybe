require "test_helper"

class AccountableSparklinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "should get show for depository" do
    get accountable_sparkline_url("depository")
    assert_response :success
  end

  test "should handle sparkline errors gracefully" do
    # Mock an error in the balance_series method
    Balance::ChartSeriesBuilder.any_instance.stubs(:balance_series).raises(StandardError.new("Test error"))

    get accountable_sparkline_url("depository")
    assert_response :success
    assert_match /Error/, response.body
  end
end
