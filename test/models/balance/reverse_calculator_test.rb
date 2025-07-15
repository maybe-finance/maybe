require "test_helper"

class Balance::ReverseCalculatorTest < ActiveSupport::TestCase
  include LedgerTestingHelper

  # When syncing backwards, we start with the account balance and generate everything from there.
  test "when missing anchor and no entries, falls back to cached account balance" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: []
    )

    assert_equal 20000, account.balance

    calculated = Balance::ReverseCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 20000, cash_balance: 20000 } ]
      ]
    )
  end

  # An artificial constraint we put on the reverse sync because it's confusing in both the code and the UI
  # to think about how an absolute "Valuation" affects balances when syncing backwards. Furthermore, since
  # this is typically a Plaid sync, we expect Plaid to provide us the history.
  # Note: while "reconciliation" valuations don't affect balance, `current_anchor` and `opening_anchor` do.
  test "reconciliation valuations do not affect balance for reverse syncs" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 20000 },
        { type: "reconciliation", date: 1.day.ago, balance: 17000 }, # Ignored
        { type: "reconciliation", date: 2.days.ago, balance: 17000 }, # Ignored
        { type: "opening_anchor", date: 4.days.ago, balance: 15000 }
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    # The "opening anchor" works slightly differently than most would expect. Since it's an artificial
    # value provided by the user to set the date/balance of the start of the account, we must assume
    # that there are "missing" entries following it. Because of this, we cannot "carry forward" this value
    # like we do for a "forward sync". We simply sync backwards normally, then set the balance on opening
    # date equal to this anchor. This is not "ideal", but is a constraint put on us since we cannot guarantee
    # a 100% full entries history.
    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 20000, cash_balance: 20000 } ], # Current anchor
        [ 1.day.ago, { balance: 20000, cash_balance: 20000 } ],
        [ 2.days.ago, { balance: 20000, cash_balance: 20000 } ],
        [ 3.days.ago, { balance: 20000, cash_balance: 20000 } ],
        [ 4.days.ago, { balance: 15000, cash_balance: 15000 } ] # Opening anchor
      ]
    )
  end

  # Investment account balances are made of two components: cash and holdings.
  test "anchors on investment accounts calculate cash balance dynamically based on holdings value" do
    account = create_account_with_ledger(
      account: { type: Investment, balance: 20000, cash_balance: 10000, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 20000 }, # "Total account value is $20,000 today"
        { type: "opening_anchor", date: 1.day.ago, balance: 15000 } # "Total account value was $15,000 at the start of the account"
      ],
      holdings: [
        { date: Date.current, ticker: "AAPL", qty: 100, price: 100, amount: 10000 },
        { date: 1.day.ago, ticker: "AAPL", qty: 100, price: 100, amount: 10000 }
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 20000, cash_balance: 10000 } ], # Since $10,000 of holdings, cash has to be $10,000 to reach $20,000 total value
        [ 1.day.ago, { balance: 15000, cash_balance: 5000 } ] # Since $10,000 of holdings, cash has to be $5,000 to reach $15,000 total value
      ]
    )
  end

  test "transactions on depository accounts affect cash balance" do
    account = create_account_with_ledger(
      account: { type: Depository, balance: 20000, cash_balance: 20000, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 20000 },
        { type: "transaction", date: 4.days.ago, amount: -500 }, # income
        { type: "transaction", date: 2.days.ago, amount: 100 } # expense
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 20000, cash_balance: 20000 } ], # Current balance
        [ 1.day.ago, { balance: 20000, cash_balance: 20000 } ], # No change
        [ 2.days.ago, { balance: 20000, cash_balance: 20000 } ], # After expense (+100)
        [ 3.days.ago, { balance: 20100, cash_balance: 20100 } ], # Before expense
        [ 4.days.ago, { balance: 20100, cash_balance: 20100 } ], # After income (-500)
        [ 5.days.ago, { balance: 19600, cash_balance: 19600 } ] # After income (-500)
      ]
    )
  end

  test "transactions on credit card accounts affect cash balance inversely" do
    account = create_account_with_ledger(
      account: { type: CreditCard, balance: 2000, cash_balance: 2000, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 2000 },
        { type: "transaction", date: 2.days.ago, amount: 100 }, # expense (increases cash balance)
        { type: "transaction", date: 4.days.ago, amount: -500 } # CC payment (reduces cash balance)
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    # Reversed order: showing how we work backwards
    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 2000, cash_balance: 2000 } ],  # Current balance
        [ 1.day.ago, { balance: 2000, cash_balance: 2000 } ], # No change
        [ 2.days.ago, { balance: 2000, cash_balance: 2000 } ], # After expense (+100)
        [ 3.days.ago, { balance: 1900, cash_balance: 1900 } ], # Before expense
        [ 4.days.ago, { balance: 1900, cash_balance: 1900 } ], # After CC payment (-500)
        [ 5.days.ago, { balance: 2400, cash_balance: 2400 } ]
      ]
    )
  end

  # A loan is a special case where despite being a "non-cash" account, it is typical to have "payment" transactions that reduce the loan principal (non cash balance)
  test "loan payment transactions affect non cash balance" do
    account = create_account_with_ledger(
      account: { type: Loan, balance: 198000, cash_balance: 0, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 198000 },
        # "Loan payment" of $2000, which reduces the principal
        # TODO: We'll eventually need to calculate which portion of the txn was "interest" vs. "principal", but for now we'll just assume it's all principal
        # since we don't have a first-class way to track interest payments yet.
        { type: "transaction", date: 1.day.ago.to_date, amount: -2000 }
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 198000, cash_balance: 0 } ],
        [ 1.day.ago, { balance: 198000, cash_balance: 0 } ],
        [ 2.days.ago, { balance: 200000, cash_balance: 0 } ]
      ]
    )
  end

  test "non cash accounts can only use valuations and transactions will be recorded but ignored for balance calculation" do
    [ Property, Vehicle, OtherAsset, OtherLiability ].each do |account_type|
      account = create_account_with_ledger(
        account: { type: account_type, balance: 1000, cash_balance: 0, currency: "USD" },
        entries: [
          { type: "current_anchor", date: Date.current, balance: 1000 },

          # Will be ignored for balance calculation due to account type of non-cash
          { type: "transaction", date: 1.day.ago, amount: -100 }
        ]
      )

      calculated = Balance::ReverseCalculator.new(account).calculate

      assert_calculated_ledger_balances(
        calculated_data: calculated,
        expected_balances: [
          [ Date.current, { balance: 1000, cash_balance: 0 } ],
          [ 1.day.ago, { balance: 1000, cash_balance: 0 } ],
          [ 2.days.ago, { balance: 1000, cash_balance: 0 } ]
        ]
      )
    end
  end

  # When syncing backwards, trades from the past should NOT affect the current balance or previous balances.
  # They should only affect the *cash* component of the historical balances
  test "holdings and trades sync" do
    # Account starts with $20,000 total value, $19,000 cash, $1,000 in holdings
    account = create_account_with_ledger(
      account: { type: Investment, balance: 20000, cash_balance: 19000, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 20000 },
        # Bought 10 AAPL shares 1 day ago, so cash is $19,000, $1,000 in holdings, total value is $20,000
        { type: "trade", date: 1.day.ago.to_date, ticker: "AAPL", qty: 10, price: 100 }
      ],
      holdings: [
        { date: Date.current, ticker: "AAPL", qty: 10, price: 100, amount: 1000 },
        { date: 1.day.ago.to_date, ticker: "AAPL", qty: 10, price: 100, amount: 1000 }
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    # Given constant prices, overall balance (account value) should be constant
    # (the single trade doesn't affect balance; it just alters cash vs. holdings composition)
    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 20000, cash_balance: 19000 } ],      # Current: $19k cash + $1k holdings (anchor)
        [ 1.day.ago.to_date, { balance: 20000, cash_balance: 19000 } ], # After trade: $19k cash + $1k holdings
        [ 2.days.ago.to_date, { balance: 20000, cash_balance: 20000 } ] # At first, account is 100% cash, no holdings (no trades)
      ]
    )
  end

  # A common scenario with Plaid is they'll give us holding records for today, but no trade history for some of them.
  # This is because they only supply 2 years worth of historical data.  Our system must properly handle this.
  test "properly calculates balances when a holding has no trade history" do
    # Account starts with $20,000 total value, $19,000 cash, $1,000 in holdings ($500 AAPL, $500 MSFT)
    account = create_account_with_ledger(
      account: { type: Investment, balance: 20000, cash_balance: 19000, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 20000 },
        # A holding *with* trade history (5 shares of AAPL, purchased 1 day ago)
        { type: "trade", date: 1.day.ago.to_date, ticker: "AAPL", qty: 5, price: 100 }
      ],
      holdings: [
        # AAPL holdings
        { date: Date.current, ticker: "AAPL", qty: 5, price: 100, amount: 500 },
        { date: 1.day.ago.to_date, ticker: "AAPL", qty: 5, price: 100, amount: 500 },
        # MSFT holdings without trade history - Balance calculator doesn't care how the holdings were created. It just reads them and assumes they are accurate.
        { date: Date.current, ticker: "MSFT", qty: 5, price: 100, amount: 500 },
        { date: 1.day.ago.to_date, ticker: "MSFT", qty: 5, price: 100, amount: 500 },
        { date: 2.days.ago.to_date, ticker: "MSFT", qty: 5, price: 100, amount: 500 }
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        [ Date.current, { balance: 20000, cash_balance: 19000 } ],      # Current: $19k cash + $1k holdings ($500 MSFT, $500 AAPL)
        [ 1.day.ago.to_date, { balance: 20000, cash_balance: 19000 } ], # After AAPL trade: $19k cash + $1k holdings
        [ 2.days.ago.to_date, { balance: 20000, cash_balance: 19500 } ] # Before AAPL trade: $19.5k cash + $500 MSFT
      ]
    )
  end

  test "uses provider reported holdings and cash value on current day" do
    # Implied holdings value of $1,000 from provider
    account = create_account_with_ledger(
      account: { type: Investment, balance: 20000, cash_balance: 19000, currency: "USD" },
      entries: [
        { type: "current_anchor", date: Date.current, balance: 20000 },
        { type: "opening_anchor", date: 2.days.ago, balance: 15000 }
      ],
      holdings: [
        # Create holdings that differ in value from provider ($2,000 vs. the $1,000 reported by provider)
        { date: Date.current, ticker: "AAPL", qty: 10, price: 100, amount: 2000 },
        { date: 1.day.ago, ticker: "AAPL", qty: 10, price: 100, amount: 2000 }
      ]
    )

    calculated = Balance::ReverseCalculator.new(account).calculate

    assert_calculated_ledger_balances(
      calculated_data: calculated,
      expected_balances: [
        # No matter what, we force current day equal to the "anchor" balance (what provider gave us), and let "cash" float based on holdings value
        # This ensures the user sees the same top-line number reported by the provider (even if it creates a discrepancy in the cash balance)
        [ Date.current, { balance: 20000, cash_balance: 18000 } ],
        [ 1.day.ago, { balance: 20000, cash_balance: 18000 } ],
        [ 2.days.ago, { balance: 15000, cash_balance: 15000 } ] # Opening anchor sets absolute balance
      ]
    )
  end
end
