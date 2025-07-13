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
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: []
    )

    assert_equal 0, account.balances.count

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 0, cash_balance: 0 } ]
      ]
    )
  end

  # Our system ensures all manual accounts have an opening anchor (for UX), but we should be able to handle a missing anchor by starting at 0 (i.e. "fresh account with no history")
  test "account without opening anchor starts at zero balance" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: [
        { type: "transaction", date: 2.days.ago.to_date, amount: -1000 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    # Since we start at 0, this transaction (inflow) simply increases balance from 0 -> 1000
    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ 3.days.ago.to_date, { balance: 0, cash_balance: 0 } ],
        [ 2.days.ago.to_date, { balance: 1000, cash_balance: 1000 } ]
      ]
    )
  end

  test "reconciliation valuation sets absolute balance before applying subsequent transactions" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: [
        { type: "reconciliation", date: 3.days.ago.to_date, balance: 18000 },
        { type: "transaction", date: 2.days.ago.to_date, amount: -1000 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    # First valuation sets balance to 18000, then transaction increases balance to 19000
    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ 3.days.ago.to_date, { balance: 18000, cash_balance: 18000 } ],
        [ 2.days.ago.to_date, { balance: 19000, cash_balance: 19000 } ]
      ]
    )
  end

  test "cash-only accounts (depository, credit card) use valuations where cash balance equals total balance" do
    [ Depository, CreditCard ].each do |account_type|
      account = create_account_with_ledger(
        account: { type: account_type, balance: 10000, cash_balance: 10000, currency: "USD" },
        entries: [
          { type: "opening_anchor", date: 3.days.ago.to_date, balance: 17000 },
          { type: "reconciliation", date: 2.days.ago.to_date, balance: 18000 }
        ]
      )

      calculated = Balance::ForwardCalculator.new(account).calculate

      assert_calculated_ledger_balances(
        calculated_data: calculated,
        expected_balances: [
          [ 3.days.ago.to_date, { balance: 17000, cash_balance: 17000 } ],
          [ 2.days.ago.to_date, { balance: 18000, cash_balance: 18000 } ]
        ]
      )
    end
  end

  test "non-cash accounts (property, loan) use valuations where cash balance is always zero" do
    [ Property, Loan ].each do |account_type|
      account = create_account_with_ledger(
        account: { type: account_type, balance: 10000, cash_balance: 10000, currency: "USD" },
        entries: [
          { type: "opening_anchor", date: 3.days.ago.to_date, balance: 17000 },
          { type: "reconciliation", date: 2.days.ago.to_date, balance: 18000 }
        ]
      )

      calculated = Balance::ForwardCalculator.new(account).calculate

      assert_calculated_ledger_balances(
        calculated_data: calculated,
        expected_balances: [
          [ 3.days.ago.to_date, { balance: 17000, cash_balance: 0.0 } ],
          [ 2.days.ago.to_date, { balance: 18000, cash_balance: 0.0 } ]
        ]
      )
    end
  end

  test "mixed accounts (investment) use valuations where cash balance is total minus holdings" do
    account = create_account_with_ledger(
      account: { type: Investment, balance: 10000, cash_balance: 10000, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 3.days.ago.to_date, balance: 17000 },
        { type: "reconciliation", date: 2.days.ago.to_date, balance: 18000 }
      ]
    )

    # Without holdings, cash balance equals total balance
    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ 3.days.ago.to_date, { balance: 17000, cash_balance: 17000 } ],
        [ 2.days.ago.to_date, { balance: 18000, cash_balance: 18000 } ]
      ]
    )
  end

  # ------------------------------------------------------------------------------------------------
  # All Cash accounts (Depository, CreditCard)
  # ------------------------------------------------------------------------------------------------

  test "transactions on depository accounts affect cash balance" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 5.days.ago.to_date, balance: 20000 },
        { type: "transaction", date: 4.days.ago.to_date, amount: -500 }, # income
        { type: "transaction", date: 2.days.ago.to_date, amount: 100 } # expense
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ 5.days.ago.to_date, { balance: 20000, cash_balance: 20000 } ],
        [ 4.days.ago.to_date, { balance: 20500, cash_balance: 20500 } ],
        [ 3.days.ago.to_date, { balance: 20500, cash_balance: 20500 } ],
        [ 2.days.ago.to_date, { balance: 20400, cash_balance: 20400 } ]
      ]
    )
  end


  test "transactions on credit card accounts affect cash balance inversely" do
    account = create_account_with_ledger(
      account: { type: CreditCard, balance: 10000, cash_balance: 10000, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 5.days.ago.to_date, balance: 1000 },
        { type: "transaction", date: 4.days.ago.to_date, amount: -500 }, # CC payment
        { type: "transaction", date: 2.days.ago.to_date, amount: 100 } # expense
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ 5.days.ago.to_date, { balance: 1000, cash_balance: 1000 } ],
        [ 4.days.ago.to_date, { balance: 500, cash_balance: 500 } ],
        [ 3.days.ago.to_date, { balance: 500, cash_balance: 500 } ],
        [ 2.days.ago.to_date, { balance: 600, cash_balance: 600 } ]
      ]
    )
  end

  test "depository account with transactions and balance reconciliations" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: [
        { type: "opening_anchor", date: 10.days.ago.to_date, balance: 20000 },
        { type: "transaction", date: 8.days.ago.to_date, amount: -5000 },
        { type: "reconciliation", date: 6.days.ago.to_date, balance: 17000 },
        { type: "transaction", date: 6.days.ago.to_date, amount: -500 },
        { type: "transaction", date: 4.days.ago.to_date, amount: -500 },
        { type: "reconciliation", date: 3.days.ago.to_date, balance: 17000 },
        { type: "transaction", date: 1.day.ago.to_date, amount: 100 }
      ]
    )

    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ 10.days.ago.to_date, { balance: 20000, cash_balance: 20000 } ],
        [ 9.days.ago.to_date, { balance: 20000, cash_balance: 20000 } ],
        [ 8.days.ago.to_date, { balance: 25000, cash_balance: 25000 } ],
        [ 7.days.ago.to_date, { balance: 25000, cash_balance: 25000 } ],
        [ 6.days.ago.to_date, { balance: 17000, cash_balance: 17000 } ],
        [ 5.days.ago.to_date, { balance: 17000, cash_balance: 17000 } ],
        [ 4.days.ago.to_date, { balance: 17500, cash_balance: 17500 } ],
        [ 3.days.ago.to_date, { balance: 17000, cash_balance: 17000 } ],
        [ 2.days.ago.to_date, { balance: 17000, cash_balance: 17000 } ],
        [ 1.day.ago.to_date, { balance: 16900, cash_balance: 16900 } ]
      ]
    )
  end

  test "accounts with transactions in multiple currencies convert to the account currency" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
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
      expected_balances: [
        [ 4.days.ago.to_date, { balance: 100, cash_balance: 100 } ],
        [ 3.days.ago.to_date, { balance: 200, cash_balance: 200 } ],
        [ 2.days.ago.to_date, { balance: 500, cash_balance: 500 } ],
        [ 1.day.ago.to_date, { balance: 1100, cash_balance: 1100 } ]
      ]
    )
  end

  # A loan is a special case where despite being a "non-cash" account, it is typical to have "payment" transactions that reduce the loan principal (non cash balance)
  test "loan payment transactions affect non cash balance" do
    account = create_account_with_ledger(
      account: { type: Loan, balance: 10000, cash_balance: 0, currency: "USD" },
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
      expected_balances: [
        [ 2.days.ago.to_date, { balance: 20000, cash_balance: 0 } ],
        [ 1.day.ago.to_date, { balance: 18000, cash_balance: 0 } ]
      ]
    )
  end

  test "non cash accounts can only use valuations and transactions will be recorded but ignored for balance calculation" do
    [ Property, Vehicle, OtherAsset, OtherLiability ].each do |account_type|
      account = create_account_with_ledger(
        account: { type: account_type, balance: 10000, cash_balance: 10000, currency: "USD" },
        entries: [
          { type: "opening_anchor", date: 3.days.ago.to_date, balance: 500000 },

          # Will be ignored for balance calculation due to account type of non-cash
          { type: "transaction", date: 2.days.ago.to_date, amount: -50000 }
        ]
      )

      calculated = Balance::ForwardCalculator.new(account).calculate

      assert_calculated_ledger_balances(
        calculated_data: calculated,
        expected_balances: [
          [ 3.days.ago.to_date, { balance: 500000, cash_balance: 0 } ],
          [ 2.days.ago.to_date, { balance: 500000, cash_balance: 0 } ]
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
      account: { type: Investment, balance: 10000, cash_balance: 10000, currency: "USD" },
      entries: [
        # Account starts with brokerage cash of $5000 and no holdings
        { type: "opening_anchor", date: 3.days.ago.to_date, balance: 5000 },
        # Share purchase reduces cash balance by $1000, but keeps overall balance same
        { type: "trade", date: 1.day.ago.to_date, ticker: "AAPL", qty: 10, price: 100 }
      ],
      holdings: [
        # Holdings calculator will calculate $1000 worth of holdings
        { date: 1.day.ago.to_date, ticker: "AAPL", qty: 10, price: 100, amount: 1000 },
        { date: Date.current, ticker: "AAPL", qty: 10, price: 100, amount: 1000 }
      ]
    )

    # Given constant prices, overall balance (account value) should be constant
    # (the single trade doesn't affect balance; it just alters cash vs. holdings composition)
    calculated = Balance::ForwardCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ 3.days.ago.to_date, { balance: 5000, cash_balance: 5000 } ],
        [ 2.days.ago.to_date, { balance: 5000, cash_balance: 5000 } ],
        [ 1.day.ago.to_date, { balance: 5000, cash_balance: 4000 } ],
        [ Date.current, { balance: 5000, cash_balance: 4000 } ]
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
