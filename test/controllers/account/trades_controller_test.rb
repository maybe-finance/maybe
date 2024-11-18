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

  test "creates deposit entry" do
    from_account = accounts(:depository) # Account the deposit is coming from

    assert_difference -> { Account::Entry.count } => 2,
                      -> { Account::Transaction.count } => 2,
                      -> { Account::Transfer.count } => 1 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "transfer_in",
          date: Date.current,
          amount: 10,
          currency: "USD",
          transfer_account_id: from_account.id
        }
      }
    end

    assert_redirected_to @entry.account
  end

  test "creates withdrawal entry" do
    to_account = accounts(:depository) # Account the withdrawal is going to

    assert_difference -> { Account::Entry.count } => 2,
                      -> { Account::Transaction.count } => 2,
                      -> { Account::Transfer.count } => 1 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "transfer_out",
          date: Date.current,
          amount: 10,
          currency: "USD",
          transfer_account_id: to_account.id
        }
      }
    end

    assert_redirected_to @entry.account
  end

  test "deposit and withdrawal has optional transfer account" do
    assert_difference -> { Account::Entry.count } => 1,
                      -> { Account::Transaction.count } => 1,
                      -> { Account::Transfer.count } => 0 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "transfer_out",
          date: Date.current,
          amount: 10,
          currency: "USD"
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.positive?
    assert created_entry.marked_as_transfer
    assert_redirected_to @entry.account
  end

  test "creates interest entry" do
    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], 1 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "interest",
          date: Date.current,
          amount: 10,
          currency: "USD"
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.negative?
    assert_redirected_to @entry.account
  end

  test "creates trade buy entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count", "Security.count" ], 1 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "buy",
          date: Date.current,
          ticker: "NVDA (NASDAQ)",
          qty: 10,
          price: 10
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.positive?
    assert created_entry.account_trade.qty.positive?
    assert_equal "Transaction created successfully.", flash[:notice]
    assert_enqueued_with job: SyncJob
    assert_redirected_to @entry.account
  end

  test "creates trade sell entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count" ], 1 do
      post account_trades_url(@entry.account), params: {
        account_entry: {
          type: "sell",
          ticker: "AAPL (NYSE)",
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
    assert_enqueued_with job: SyncJob
    assert_redirected_to @entry.account
  end
end
