require "test_helper"

# The "forward calculator" is used for all **manual** accounts where balance tracking is done through entries and NOT from an external data provider.
class Balance::ForwardCalculatorTest < ActiveSupport::TestCase
  include LedgerTestingHelper

  # ------------------------------------------------------------------------------------------------
  # General tests for all account types
  # ------------------------------------------------------------------------------------------------

  # When syncing forwards, we don't care about the account balance.  We generate everything based on entries, starting from 0.
  test "no entries sync" do
    account = create_account_with_ledger(
      account: { type: Depository, currency: "USD" },
      entries: []
    )

    assert_equal 0, account.balances.count

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: Date.current,
          legacy_balances: { balance: 0, cash_balance: 0 },
          balances: { start: 0, start_cash: 0, start_non_cash: 0, end_cash: 0, end_non_cash: 0, end: 0 },
          flows: 0,
          adjustments: 0
        }
      ]
    )
  end

  # Our system ensures all manual accounts have an opening anchor (for UX), but we should be able to handle a missing anchor by starting at 0 (i.e. "fresh account with no history")
  test "account without opening anchor starts at zero balance" do
    account = create_account_with_ledger(
      account: { type: Depository, currency: "USD" },
      entries: [
        { type: "transaction", date: 2.days.ago.to_date, amount: -1000 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    # Since we start at 0, this transaction (inflow) simply increases balance from 0 -> 1000
    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 0, cash_balance: 0 },
          balances: { start: 0, start_cash: 0, start_non_cash: 0, end_cash: 0, end_non_cash: 0, end: 0 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 1000, cash_balance: 1000 },
          balances: { start: 0, start_cash: 0, start_non_cash: 0, end_cash: 1000, end_non_cash: 0, end: 1000 },
          flows: { cash_inflows: 1000, cash_outflows: 0 },
          adjustments: 0
        }
      ]
    )
  end

  test "reconciliation valuation sets absolute balance before applying subsequent transactions" do
    account = create_account_with_ledger(
      account: { type: Depository, currency: "USD" },
      entries: [
        { type: "reconciliation", date: 3.days.ago.to_date, balance: 18000 },
        { type: "transaction", date: 2.days.ago.to_date, amount: -1000 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    # First valuation sets balance to 18000, then transaction increases balance to 19000
    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 18000, cash_balance: 18000 },
          balances: { start: 0, start_cash: 0, start_non_cash: 0, end_cash: 18000, end_non_cash: 0, end: 18000 },
          flows: 0,
          adjustments: { cash_adjustments: 18000, non_cash_adjustments: 0 }
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 19000, cash_balance: 19000 },
          balances: { start: 18000, start_cash: 18000, start_non_cash: 0, end_cash: 19000, end_non_cash: 0, end: 19000 },
          flows: { cash_inflows: 1000, cash_outflows: 0 },
          adjustments: 0
        }
      ]
    )
  end

  test "cash-only accounts (depository, credit card) use valuations where cash balance equals total balance" do
    [ Depository, CreditCard ].each do |account_type|
      account = create_account_with_ledger(
        account: { type: account_type, currency: "USD" },
        entries: [
          { type: "opening_anchor", date: 3.days.ago.to_date, balance: 17000 },
          { type: "reconciliation", date: 2.days.ago.to_date, balance: 18000 }
        ]
      )

      calculated = Balance::ForwardCalculator.new(account).calculate

      assert_calculated_ledger_balances(
        calculated_data: calculated,
        expected_data: [
          {
            date: 3.days.ago.to_date,
            legacy_balances: { balance: 17000, cash_balance: 17000 },
            balances: { start: 17000, start_cash: 17000, start_non_cash: 0, end_cash: 17000, end_non_cash: 0, end: 17000 },
            flows: 0,
            adjustments: 0
          },
          {
            date: 2.days.ago.to_date,
            legacy_balances: { balance: 18000, cash_balance: 18000 },
            balances: { start: 17000, start_cash: 17000, start_non_cash: 0, end_cash: 18000, end_non_cash: 0, end: 18000 },
            flows: 0,
            adjustments: { cash_adjustments: 1000, non_cash_adjustments: 0 }
          }
        ]
      )
    end
  end

  test "non-cash accounts (property, loan) use valuations where cash balance is always zero" do
    [ Property, Loan ].each do |account_type|
      account = create_account_with_ledger(
        account: { type: account_type, currency: "USD" },
        entries: [
          { type: "opening_anchor", date: 3.days.ago.to_date, balance: 17000 },
          { type: "reconciliation", date: 2.days.ago.to_date, balance: 18000 }
        ]
      )

      calculated = Balance::ForwardCalculator.new(account).calculate

      assert_calculated_ledger_balances(
        calculated_data: calculated,
        expected_data: [
          {
            date: 3.days.ago.to_date,
            legacy_balances: { balance: 17000, cash_balance: 0.0 },
            balances: { start: 17000, start_cash: 0, start_non_cash: 17000, end_cash: 0, end_non_cash: 17000, end: 17000 },
            flows: 0,
            adjustments: 0
          },
          {
            date: 2.days.ago.to_date,
            legacy_balances: { balance: 18000, cash_balance: 0.0 },
            balances: { start: 17000, start_cash: 0, start_non_cash: 17000, end_cash: 0, end_non_cash: 18000, end: 18000 },
            flows: 0,
            adjustments: { cash_adjustments: 0, non_cash_adjustments: 1000 }
          }
        ]
      )
    end
  end

  test "mixed accounts (investment) use valuations where cash balance is total minus holdings" do
    account = create_account_with_ledger(
      account: { type: Investment, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 3.days.ago.to_date, balance: 17000 },
        { type: "reconciliation", date: 2.days.ago.to_date, balance: 18000 }
      ]
    )

    # Without holdings, cash balance equals total balance
    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 17000, cash_balance: 17000 },
          balances: { start: 17000, start_cash: 17000, start_non_cash: 0, end_cash: 17000, end_non_cash: 0, end: 17000 },
          flows: { market_flows: 0 },
          adjustments: 0
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 18000, cash_balance: 18000 },
          balances: { start: 17000, start_cash: 17000, start_non_cash: 0, end_cash: 18000, end_non_cash: 0, end: 18000 },
          flows: { market_flows: 0 },
          adjustments: { cash_adjustments: 1000, non_cash_adjustments: 0 } # Since no holdings present, adjustment is all cash
        }
      ]
    )
  end

  # ------------------------------------------------------------------------------------------------
  # All Cash accounts (Depository, CreditCard)
  # ------------------------------------------------------------------------------------------------

  test "transactions on depository accounts affect cash balance" do
    account = create_account_with_ledger(
      account: { type: Depository, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 5.days.ago.to_date, balance: 20000 },
        { type: "transaction", date: 4.days.ago.to_date, amount: -500 }, # income
        { type: "transaction", date: 2.days.ago.to_date, amount: 100 } # expense
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 5.days.ago.to_date,
          legacy_balances: { balance: 20000, cash_balance: 20000 },
          balances: { start: 20000, start_cash: 20000, start_non_cash: 0, end_cash: 20000, end_non_cash: 0, end: 20000 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 4.days.ago.to_date,
          legacy_balances: { balance: 20500, cash_balance: 20500 },
          balances: { start: 20000, start_cash: 20000, start_non_cash: 0, end_cash: 20500, end_non_cash: 0, end: 20500 },
          flows: { cash_inflows: 500, cash_outflows: 0 },
          adjustments: 0
        },
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 20500, cash_balance: 20500 },
          balances: { start: 20500, start_cash: 20500, start_non_cash: 0, end_cash: 20500, end_non_cash: 0, end: 20500 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 20400, cash_balance: 20400 },
          balances: { start: 20500, start_cash: 20500, start_non_cash: 0, end_cash: 20400, end_non_cash: 0, end: 20400 },
          flows: { cash_inflows: 0, cash_outflows: 100 },
          adjustments: 0
        }
      ]
    )
  end


  test "transactions on credit card accounts affect cash balance inversely" do
    account = create_account_with_ledger(
      account: { type: CreditCard, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 5.days.ago.to_date, balance: 1000 },
        { type: "transaction", date: 4.days.ago.to_date, amount: -500 }, # CC payment
        { type: "transaction", date: 2.days.ago.to_date, amount: 100 } # expense
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 5.days.ago.to_date,
          legacy_balances: { balance: 1000, cash_balance: 1000 },
          balances: { start: 1000, start_cash: 1000, start_non_cash: 0, end_cash: 1000, end_non_cash: 0, end: 1000 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 4.days.ago.to_date,
          legacy_balances: { balance: 500, cash_balance: 500 },
          balances: { start: 1000, start_cash: 1000, start_non_cash: 0, end_cash: 500, end_non_cash: 0, end: 500 },
          flows: { cash_inflows: 500, cash_outflows: 0 },
          adjustments: 0
        },
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 500, cash_balance: 500 },
          balances: { start: 500, start_cash: 500, start_non_cash: 0, end_cash: 500, end_non_cash: 0, end: 500 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 600, cash_balance: 600 },
          balances: { start: 500, start_cash: 500, start_non_cash: 0, end_cash: 600, end_non_cash: 0, end: 600 },
          flows: { cash_inflows: 0, cash_outflows: 100 },
          adjustments: 0
        }
      ]
    )
  end

  test "depository account with transactions and balance reconciliations" do
    account = create_account_with_ledger(
      account: { type: Depository, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 4.days.ago.to_date, balance: 20000 },
        { type: "transaction", date: 3.days.ago.to_date, amount: -5000 },
        { type: "reconciliation", date: 2.days.ago.to_date, balance: 17000 },
        { type: "transaction", date: 1.day.ago.to_date, amount: -500 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 4.days.ago.to_date,
          legacy_balances: { balance: 20000, cash_balance: 20000 },
          balances: { start: 20000, start_cash: 20000, start_non_cash: 0, end_cash: 20000, end_non_cash: 0, end: 20000 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 25000, cash_balance: 25000 },
          balances: { start: 20000, start_cash: 20000, start_non_cash: 0, end_cash: 25000, end_non_cash: 0, end: 25000 },
          flows: { cash_inflows: 5000, cash_outflows: 0 },
          adjustments: 0
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 17000, cash_balance: 17000 },
          balances: { start: 25000, start_cash: 25000, start_non_cash: 0, end_cash: 17000, end_non_cash: 0, end: 17000 },
          flows: 0,
          adjustments: { cash_adjustments: -8000, non_cash_adjustments: 0 }
        },
        {
          date: 1.day.ago.to_date,
          legacy_balances: { balance: 17500, cash_balance: 17500 },
          balances: { start: 17000, start_cash: 17000, start_non_cash: 0, end_cash: 17500, end_non_cash: 0, end: 17500 },
          flows: { cash_inflows: 500, cash_outflows: 0 },
          adjustments: 0
        }
      ]
    )
  end

  test "accounts with transactions in multiple currencies convert to the account currency and flows are stored in account currency" do
    account = create_account_with_ledger(
      account: { type: Depository, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 4.days.ago.to_date, balance: 100 },
        { type: "transaction", date: 3.days.ago.to_date, amount: -100 },
        { type: "transaction", date: 2.days.ago.to_date, amount: -300 },
        # Transaction in different currency than the account's main currency
        { type: "transaction", date: 1.day.ago.to_date, amount: -500, currency: "EUR" } # €500 * 1.2 = $600
      ],
      exchange_rates: [
        { date: 1.day.ago.to_date, from: "EUR", to: "USD", rate: 1.2 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 4.days.ago.to_date,
          legacy_balances: { balance: 100, cash_balance: 100 },
          balances: { start: 100, start_cash: 100, start_non_cash: 0, end_cash: 100, end_non_cash: 0, end: 100 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 200, cash_balance: 200 },
          balances: { start: 100, start_cash: 100, start_non_cash: 0, end_cash: 200, end_non_cash: 0, end: 200 },
          flows: { cash_inflows: 100, cash_outflows: 0 },
          adjustments: 0
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 500, cash_balance: 500 },
          balances: { start: 200, start_cash: 200, start_non_cash: 0, end_cash: 500, end_non_cash: 0, end: 500 },
          flows: { cash_inflows: 300, cash_outflows: 0 },
          adjustments: 0
        },
        {
          date: 1.day.ago.to_date,
          legacy_balances: { balance: 1100, cash_balance: 1100 },
          balances: { start: 500, start_cash: 500, start_non_cash: 0, end_cash: 1100, end_non_cash: 0, end: 1100 },
          flows: { cash_inflows: 600, cash_outflows: 0 }, # Cash inflow is the USD equivalent of €500 (converted for balances table)
          adjustments: 0
        }
      ]
    )
  end

  # A loan is a special case where despite being a "non-cash" account, it is typical to have "payment" transactions that reduce the loan principal (non cash balance)
  test "loan payment transactions affect non cash balance" do
    account = create_account_with_ledger(
      account: { type: Loan, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 2.days.ago.to_date, balance: 20000 },
        # "Loan payment" of $2000, which reduces the principal
        # TODO: We'll eventually need to calculate which portion of the txn was "interest" vs. "principal", but for now we'll just assume it's all principal
        # since we don't have a first-class way to track interest payments yet.
        { type: "transaction", date: 1.day.ago.to_date, amount: -2000 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 20000, cash_balance: 0 },
          balances: { start: 20000, start_cash: 0, start_non_cash: 20000, end_cash: 0, end_non_cash: 20000, end: 20000 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 1.day.ago.to_date,
          legacy_balances: { balance: 18000, cash_balance: 0 },
          balances: { start: 20000, start_cash: 0, start_non_cash: 20000, end_cash: 0, end_non_cash: 18000, end: 18000 },
          flows: { non_cash_inflows: 2000, non_cash_outflows: 0, cash_inflows: 0, cash_outflows: 0 }, # Loans are "special cases" where transactions do affect non-cash balance
          adjustments: 0
        }
      ]
    )
  end

  test "non cash accounts can only use valuations and transactions will be recorded but ignored for balance calculation" do
    [ Property, Vehicle, OtherAsset, OtherLiability ].each do |account_type|
      account = create_account_with_ledger(
        account: { type: account_type, currency: "USD" },
        entries: [
          { type: "opening_anchor", date: 3.days.ago.to_date, balance: 500000 },

          # Will be ignored for balance calculation due to account type of non-cash
          { type: "transaction", date: 2.days.ago.to_date, amount: -50000 }
        ]
      )

      calculated = Balance::ForwardCalculator.new(account).calculate

      assert_calculated_ledger_balances(
        calculated_data: calculated,
        expected_data: [
          {
            date: 3.days.ago.to_date,
            legacy_balances: { balance: 500000, cash_balance: 0 },
            balances: { start: 500000, start_cash: 0, start_non_cash: 500000, end_cash: 0, end_non_cash: 500000, end: 500000 },
            flows: 0,
            adjustments: 0
          },
          {
            date: 2.days.ago.to_date,
            legacy_balances: { balance: 500000, cash_balance: 0 },
            balances: { start: 500000, start_cash: 0, start_non_cash: 500000, end_cash: 0, end_non_cash: 500000, end: 500000 },
            flows: 0, # Despite having a transaction, non-cash accounts ignore it for balance calculation
            adjustments: 0
          }
        ]
      )
    end
  end

  # ------------------------------------------------------------------------------------------------
  # Hybrid accounts (Investment, Crypto) - these have both cash and non-cash balance components
  # ------------------------------------------------------------------------------------------------

  # A transaction increases/decreases cash balance (i.e. "deposits" and "withdrawals")
  # A trade increases/decreases cash balance (i.e. "buys" and "sells", which consume/add "brokerage cash" and create/destroy "holdings")
  # A valuation can set both cash and non-cash balances to "override" investment account value.
  # Holdings are calculated separately and fed into the balance calculator; treated as "non-cash"
  test "investment account calculates balance from transactions and trades and treats holdings as non-cash, additive to balance" do
    account = create_account_with_ledger(
      account: { type: Investment, currency: "USD" },
      entries: [
        # Account starts with brokerage cash of $5000 and no holdings
        { type: "opening_anchor", date: 3.days.ago.to_date, balance: 5000 },
        # Share purchase reduces cash balance by $1000, but keeps overall balance same
        { type: "trade", date: 1.day.ago.to_date, ticker: "AAPL", qty: 10, price: 100 }
      ],
      holdings: [
        # Holdings calculator will calculate $1000 worth of holdings
        { date: 1.day.ago.to_date, ticker: "AAPL", qty: 10, price: 100, amount: 1000 },
        { date: Date.current, ticker: "AAPL", qty: 10, price: 110, amount: 1100 } # Price increased by 10%, so holdings value goes up by $100 without a trade
      ]
    )

    # Given constant prices, overall balance (account value) should be constant
    # (the single trade doesn't affect balance; it just alters cash vs. holdings composition)
    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 3.days.ago.to_date,
          legacy_balances: { balance: 5000, cash_balance: 5000 },
          balances: { start: 5000, start_cash: 5000, start_non_cash: 0, end_cash: 5000, end_non_cash: 0, end: 5000 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 5000, cash_balance: 5000 },
          balances: { start: 5000, start_cash: 5000, start_non_cash: 0, end_cash: 5000, end_non_cash: 0, end: 5000 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 1.day.ago.to_date,
          legacy_balances: { balance: 5000, cash_balance: 4000 },
          balances: { start: 5000, start_cash: 5000, start_non_cash: 0, end_cash: 4000, end_non_cash: 1000, end: 5000 },
          flows: { cash_inflows: 0, cash_outflows: 1000, non_cash_inflows: 1000, non_cash_outflows: 0, net_market_flows: 0 }, # Decrease cash by 1000, increase holdings by 1000 (i.e. "buy" of $1000 worth of AAPL)
          adjustments: 0
        },
        {
          date: Date.current,
          legacy_balances: { balance: 5100, cash_balance: 4000 },
          balances: { start: 5000, start_cash: 4000, start_non_cash: 1000, end_cash: 4000, end_non_cash: 1100, end: 5100 },
          flows: { net_market_flows: 100 }, # Holdings value increased by 100, despite no change in portfolio quantities
          adjustments: 0
        }
      ]
    )
  end

  test "investment account can have valuations that override balance" do
    account = create_account_with_ledger(
      account: { type: Investment, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 2.days.ago.to_date, balance: 5000 },
        { type: "reconciliation", date: 1.day.ago.to_date, balance: 10000 }
      ],
      holdings: [
        { date: 3.days.ago.to_date, ticker: "AAPL", qty: 10, price: 100, amount: 1000 },
        { date: 2.days.ago.to_date, ticker: "AAPL", qty: 10, price: 100, amount: 1000 },
        { date: 1.day.ago.to_date, ticker: "AAPL", qty: 10, price: 110, amount: 1100 },
        { date: Date.current, ticker: "AAPL", qty: 10, price: 120, amount: 1200 }
      ]
    )

    # Given constant prices, overall balance (account value) should be constant
    # (the single trade doesn't affect balance; it just alters cash vs. holdings composition)
    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_data: [
        {
          date: 2.days.ago.to_date,
          legacy_balances: { balance: 5000, cash_balance: 4000 },
          balances: { start: 5000, start_cash: 4000, start_non_cash: 1000, end_cash: 4000, end_non_cash: 1000, end: 5000 },
          flows: 0,
          adjustments: 0
        },
        {
          date: 1.day.ago.to_date,
          legacy_balances: { balance: 10000, cash_balance: 8900 },
          balances: { start: 5000, start_cash: 4000, start_non_cash: 1000, end_cash: 8900, end_non_cash: 1100, end: 10000 },
          flows: { net_market_flows: 100 },
          adjustments: { cash_adjustments: 4900, non_cash_adjustments: 0 }
        },
        {
          date: Date.current,
          legacy_balances: { balance: 10100, cash_balance: 8900 },
          balances: { start: 10000, start_cash: 8900, start_non_cash: 1100, end_cash: 8900, end_non_cash: 1200, end: 10100 },
          flows: { net_market_flows: 100 },
          adjustments: 0
        }
      ]
    )
  end

  private
    def assert_balances(calculated_data:, expected_balances:)
      # Sort calculated data by date to ensure consistent ordering
      sorted_data = calculated_data.sort_by(&:date)

      # Extract actual values as [date, { balance:, cash_balance: }]
      actual_balances = sorted_data.map do |b|
        [ b.date, { balance: b.balance, cash_balance: b.cash_balance } ]
      end

      assert_equal expected_balances, actual_balances
    end
end
