require "test_helper"

class PlaidInvestmentSyncTest < ActiveSupport::TestCase
  include PlaidTestHelper

  setup do
    @plaid_account = plaid_accounts(:one)
  end

  test "syncs basic investments and handles cash holding" do
    assert_equal 0, @plaid_account.account.entries.count
    assert_equal 0, @plaid_account.account.holdings.count

    plaid_aapl_id = "aapl_id"

    transactions = [
      create_plaid_investment_transaction({
        investment_transaction_id: "inv_txn_1",
        security_id: plaid_aapl_id,
        quantity: 10,
        price: 200,
        date: 5.days.ago.to_date,
        type: "buy"
      })
    ]

    holdings = [
      create_plaid_cash_holding,
      create_plaid_holding({
        security_id: plaid_aapl_id,
        quantity: 10,
        institution_price: 200,
        cost_basis: 2000
      })
    ]

    securities = [
      create_plaid_security({
        security_id: plaid_aapl_id,
        close_price: 200,
        ticker_symbol: "AAPL"
      })
    ]

    # Cash holding should be ignored, resulting in 1, NOT 2 total holdings after sync
    assert_difference -> { Trade.count } => 1,
                      -> { Transaction.count } => 0,
                      -> { Holding.count } => 1,
                      -> { Security.count } => 0 do
      PlaidInvestmentSync.new(@plaid_account).sync!(
        transactions: transactions,
        holdings: holdings,
        securities: securities
      )
    end
  end

  # Some cash transactions from Plaid are labeled as type: "cash" while others are linked to a "cash" security
  # In both cases, we should treat them as cash-only transactions (not trades)
  test "handles cash investment transactions" do
    transactions = [
      create_plaid_investment_transaction({
        price: 1,
        quantity: 5,
        amount: 5,
        type: "fee",
        subtype: "miscellaneous fee",
        security_id: PLAID_TEST_CASH_SECURITY_ID
      })
    ]

    assert_difference -> { Trade.count } => 0,
                      -> { Transaction.count } => 1,
                      -> { Security.count } => 0 do
      PlaidInvestmentSync.new(@plaid_account).sync!(
        transactions: transactions,
        holdings: [ create_plaid_cash_holding ],
        securities: [ create_plaid_cash_security ]
      )
    end
  end
end
