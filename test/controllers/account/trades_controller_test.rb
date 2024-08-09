require "test_helper"

class Account::TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @entry = account_entries :trade
  end

  test "should get index" do
    get account_trades_url(@entry.account)
    assert_response :success
  end

  test "should get new" do
    get new_account_trade_url(@entry.account)
    assert_response :success
  end

  test "creates trade buy entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count", "Security.count" ], 1 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "buy",
          date: Date.current,
          ticker: "NVDA",
          qty: 10,
          price: 10
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.positive?
    assert created_entry.account_trade.qty.positive?
    assert_equal "Transaction created successfully.", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@entry.account)
  end

  test "creates trade sell entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count" ], 1 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "sell",
          ticker: "AAPL",
          date: Date.current,
          currency: "USD",
          qty: 10,
          price: 10
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.negative?
    assert created_entry.account_trade.qty.negative?
    assert_equal "Transaction created successfully.", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@entry.account)
  end
end
