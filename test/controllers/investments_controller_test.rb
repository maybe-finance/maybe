require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @investment = investments(:one)
  end

  test "new" do
    get new_investment_url
    assert_response :success
  end

  test "show" do
    get investment_url(@investment)
    assert_response :success
  end

  test "create" do
    assert_difference [ "Account.count", "Investment.count" ], 1 do
      post investments_url, params: {
        account: {
          accountable_type: "Investment",
          name: "New investment",
          balance: 50000,
          currency: "USD",
          subtype: "brokerage"
        }
      }
    end

    assert_redirected_to Account.order(:created_at).last
    assert_equal "Investment account created", flash[:notice]
  end

  test "update" do
    assert_no_difference [ "Account.count", "Investment.count" ] do
      patch investment_url(@investment), params: {
        account: {
          name: "Updated name",
          balance: 50000,
          currency: "USD",
          subtype: "brokerage"
        }
      }
    end

    assert_redirected_to @investment.account
    assert_equal "Investment account updated", flash[:notice]
  end
end
