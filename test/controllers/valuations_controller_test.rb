require "test_helper"

class ValuationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:checking)
  end

  test "new" do
    get new_account_valuation_url(@account)
    assert_response :success
  end

  test "create" do
    assert_difference("Valuation.count") do
      post account_valuations_url(@account), params: { valuation: { value: 1, date: Date.current, type: "Appraisal" } }
    end
  end
end
