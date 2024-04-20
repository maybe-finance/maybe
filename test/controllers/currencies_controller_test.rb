require "test_helper"

class CurrenciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "should show currency" do
    get currency_url(id: "EUR", format: :json)
    assert_response :success
  end
end
