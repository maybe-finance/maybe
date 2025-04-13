require "test_helper"

class Account::TradesControllerTest < ActionDispatch::IntegrationTest
  include EntryableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @entry = account_entries(:trade)
  end

  test "updates trade entry" do
    assert_no_difference [ "Account::Entry.count", "Account::Trade.count" ] do
      patch account_trade_url(@entry), params: {
        account_entry: {
          currency: "EUR",
          entryable_attributes: {
            id: @entry.entryable_id,
            qty: 20,
            price: 20
          }
        }
      }
    end

    @entry.reload

    assert @entry.locked?(:currency)
    assert @entry.locked?(:amount)

    assert @entry.account_trade.locked?(:qty)
    assert @entry.account_trade.locked?(:price)

    assert_enqueued_with job: SyncJob

    assert_equal 20, @entry.account_trade.qty
    assert_equal 20, @entry.account_trade.price
    assert_equal "EUR", @entry.currency

    assert_redirected_to account_url(@entry.account)
  end

  test "creates deposit entry" do
    from_account = accounts(:depository) # Account the deposit is coming from

    assert_difference -> { Account::Entry.count } => 2,
                      -> { Account::Transaction.count } => 2,
                      -> { Transfer.count } => 1 do
      post account_trades_url, params: {
        account_entry: {
          account_id: @entry.account_id,
          type: "deposit",
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
                      -> { Transfer.count } => 1 do
      post account_trades_url, params: {
        account_entry: {
          account_id: @entry.account_id,
          type: "withdrawal",
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
                      -> { Transfer.count } => 0 do
      post account_trades_url, params: {
        account_entry: {
          account_id: @entry.account_id,
          type: "withdrawal",
          date: Date.current,
          amount: 10,
          currency: "USD"
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.amount.positive?
    assert_redirected_to @entry.account
  end

  test "creates interest entry" do
    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], 1 do
      post account_trades_url, params: {
        account_entry: {
          account_id: @entry.account_id,
          type: "interest",
          date: Date.current,
          amount: 10,
          currency: "USD"
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.locked?(:currency)
    assert created_entry.locked?(:amount)

    assert created_entry.amount.negative?
    assert_redirected_to @entry.account
  end

  test "creates trade buy entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count", "Security.count" ], 1 do
      post account_trades_url, params: {
        account_entry: {
          account_id: @entry.account_id,
          type: "buy",
          date: Date.current,
          ticker: "NVDA (NASDAQ)",
          qty: 10,
          price: 10,
          currency: "USD"
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert created_entry.locked?(:currency)
    assert created_entry.locked?(:amount)

    assert created_entry.account_trade.locked?(:qty)
    assert created_entry.account_trade.locked?(:price)

    assert created_entry.amount.positive?
    assert created_entry.account_trade.qty.positive?
    assert_equal "Entry created", flash[:notice]
    assert_enqueued_with job: SyncJob
    assert_redirected_to account_url(created_entry.account)
  end

  test "creates trade sell entry" do
    assert_difference [ "Account::Entry.count", "Account::Trade.count" ], 1 do
      post account_trades_url, params: {
        account_entry: {
          account_id: @entry.account_id,
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

    assert created_entry.locked?(:currency)
    assert created_entry.locked?(:amount)

    assert created_entry.account_trade.locked?(:qty)
    assert created_entry.account_trade.locked?(:price)

    assert created_entry.amount.negative?
    assert created_entry.account_trade.qty.negative?
    assert_equal "Entry created", flash[:notice]
    assert_enqueued_with job: SyncJob
    assert_redirected_to account_url(created_entry.account)
  end
end
