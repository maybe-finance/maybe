require "test_helper"

class OtherLiabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @other_liability = other_liabilities(:one)
  end

  test "new" do
    get new_other_liability_url
    assert_response :success
  end

  test "show" do
    get other_liability_url(@other_liability)
    assert_response :success
  end

  test "create" do
    assert_difference [ "Account.count", "OtherLiability.count" ], 1 do
      post other_liabilities_url, params: {
        account: {
          accountable_type: "OtherLiability",
          name: "New other liability",
          balance: 15000,
          currency: "USD",
          subtype: "other"
        }
      }
    end

    assert_redirected_to Account.order(:created_at).last
    assert_equal "Other liability account created", flash[:notice]
  end

  test "update" do
    assert_no_difference [ "Account.count", "OtherLiability.count" ] do
      patch other_liability_url(@other_liability), params: {
        account: {
          name: "Updated name",
          balance: 15000,
          currency: "USD",
          subtype: "other"
        }
      }
    end

    assert_redirected_to @other_liability.account
    assert_equal "Other liability account updated", flash[:notice]
  end
end
