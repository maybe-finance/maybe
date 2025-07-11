require "test_helper"

# The "forward calculator" is used for all **manual** accounts where balance tracking is done through entries and NOT from an external data provider.
class Balance::ForwardCalculatorTest < ActiveSupport::TestCase
  include EntriesTestHelper

  # Different types of accounts work slightly differently with Balance vs. Cash Balance, so we test various scenarios with each type.
  setup do
    @family = families(:empty)

    # A depository account is a "cash only" account where we only track cash balance.
    @depository = @family.accounts.create!(
      name: "Test",
      balance: 20000,
      cash_balance: 20000,
      currency: "USD",
      accountable: Depository.new
    )

    @credit_card = @family.accounts.create!(
      name: "Credit Card",
      balance: 10000,
      cash_balance: 10000,
      currency: "USD",
      accountable: CreditCard.new
    )

    # An investment account is a "hybrid" where we track both cash and non-cash balances.
    @investment = @family.accounts.create!(
      name: "Investment",
      balance: 10000,
      cash_balance: 10000,
      currency: "USD",
      accountable: Investment.new
    )

    # A Property is an "asset/liability" account that we only track with valuations (not transactions, trades)
    @property = @family.accounts.create!(
      name: "Property",
      balance: 10000,
      cash_balance: 10000,
      currency: "USD",
      accountable: Property.new
    )

    @loan = @family.accounts.create!(
      name: "Loan",
      balance: 10000,
      cash_balance: 10000,
      currency: "USD",
      accountable: Loan.new
    )
  end

  # ------------------------------------------------------------------------------------------------
  # General tests for all account types
  # ------------------------------------------------------------------------------------------------

  # When syncing forwards, we don't care about the account balance.  We generate everything based on entries, starting from 0.
  test "no entries sync" do
    assert_equal 0, @depository.balances.count

    expected = [ 0 ]
    calculated = Balance::ForwardCalculator.new(@depository).calculate

    cash_balances = calculated.map(&:cash_balance)
    balances = calculated.map(&:balance)

    assert_equal expected, balances
    assert_equal expected, cash_balances
  end

  # Our system ensures all manual accounts have an opening anchor (for UX), but we should be able to handle a missing anchor by starting at 0 (i.e. "fresh account with no history")
  test "when missing opening anchor, account starts at 0 and applies entries" do
    create_transaction(account: @depository, date: 2.days.ago.to_date, amount: -1000)

    calculated = Balance::ForwardCalculator.new(@depository).calculate

    # Since we start at 0, this transaction (inflow) simply increases balance from 0 -> 1000
    expected = [ 1000 ]

    create_reconciliation_valuation(account: @depository, balance: 18000, cash_balance: 18000, date: 3.days.ago.to_date)

    balances = calculated.map(&:balance)
    cash_balances = calculated.map(&:cash_balance)

    assert_equal expected, balances
    assert_equal expected, cash_balances

    @depository.reload

    # First valuation sets balance to 18000, then transaction increases balance to 19000
    expected = [ 18000, 19000 ]
    calculated = Balance::ForwardCalculator.new(@depository).calculate

    balances = calculated.map(&:balance)
    cash_balances = calculated.map(&:cash_balance)

    assert_equal expected, balances
    assert_equal expected, cash_balances
  end

  test "any account type can use valuations only to construct balances" do
    [ @depository, @investment, @property, @loan ].each do |account|
      create_opening_anchor_valuation(account: account, balance: 17000, cash_balance: 17000, date: 3.days.ago.to_date)
      create_reconciliation_valuation(account: account, balance: 18000, cash_balance: 18000, date: 2.days.ago.to_date)

      expected = [ 17000, 18000 ]
      calculated = Balance::ForwardCalculator.new(account).calculate

      balances = calculated.map(&:balance)
      cash_balances = calculated.map(&:cash_balance)

      assert_equal expected, balances
      assert_equal expected, cash_balances
    end
  end

  # ------------------------------------------------------------------------------------------------
  # All Cash accounts (Depository, CreditCard)
  # ------------------------------------------------------------------------------------------------

  test "transactions on depository accounts affect cash balance" do
    create_opening_anchor_valuation(account: @depository, balance: 20000, cash_balance: 20000, date: 5.days.ago.to_date)
    create_transaction(account: @depository, date: 4.days.ago.to_date, amount: -500) # income
    create_transaction(account: @depository, date: 2.days.ago.to_date, amount: 100) # expense

    expected = [ 20000, 20500, 20500, 20400 ]
    calculated = Balance::ForwardCalculator.new(@depository).calculate.sort_by(&:date)

    cash_balances = calculated.map(&:cash_balance)
    balances = calculated.map(&:balance)

    assert_equal expected, balances
    assert_equal expected, cash_balances
  end


  test "transactions on credit card accounts affect cash balance inversely" do
    create_opening_anchor_valuation(account: @credit_card, balance: 1000, cash_balance: 1000, date: 5.days.ago.to_date)
    create_transaction(account: @credit_card, date: 4.days.ago.to_date, amount: -500) # CC payment
    create_transaction(account: @credit_card, date: 2.days.ago.to_date, amount: 100) # expense

    expected = [ 1000, 500, 500, 600 ]
    calculated = Balance::ForwardCalculator.new(@credit_card).calculate.sort_by(&:date)

    cash_balances = calculated.map(&:cash_balance)
    balances = calculated.map(&:balance)

    assert_equal expected, balances
    assert_equal expected, cash_balances
  end

  test "depository account with transactions and balance reconciliations" do
    create_opening_anchor_valuation(account: @depository, balance: 20000, cash_balance: 20000, date: 10.days.ago.to_date)
    create_transaction(account: @depository, date: 8.days.ago.to_date, amount: -5000)
    create_valuation(account: @depository, date: 6.days.ago.to_date, amount: 17000)
    create_transaction(account: @depository, date: 6.days.ago.to_date, amount: -500)
    create_transaction(account: @depository, date: 4.days.ago.to_date, amount: -500)
    create_valuation(account: @depository, date: 3.days.ago.to_date, amount: 17000)
    create_transaction(account: @depository, date: 1.day.ago.to_date, amount: 100)

    expected = [ 20000, 20000, 25000, 25000, 17000, 17000, 17500, 17000, 17000, 16900 ]
    calculated = Balance::ForwardCalculator.new(@depository).calculate.sort_by(&:date)

    cash_balances = calculated.map(&:cash_balance)
    balances = calculated.map(&:balance)

    assert_equal expected, balances
    assert_equal expected, cash_balances
  end

  test "accounts with transactions in multiple currencies convert to the account currency" do
    ExchangeRate.create! date: 1.day.ago.to_date, from_currency: "EUR", to_currency: "USD", rate: 1.2

    create_opening_anchor_valuation(account: @depository, balance: 100, cash_balance: 100, date: 4.days.ago.to_date)

    create_transaction(account: @depository, date: 3.days.ago.to_date, amount: -100, currency: "USD")
    create_transaction(account: @depository, date: 2.days.ago.to_date, amount: -300, currency: "USD")

    # Transaction in different currency than the account's main currency
    create_transaction(account: @depository, date: 1.day.ago.to_date, amount: -500, currency: "EUR") # €500 * 1.2 = $600

    expected = [ 100, 200, 500, 1100 ]
    calculated = Balance::ForwardCalculator.new(@depository).calculate.sort_by(&:date)

    cash_balances = calculated.map(&:cash_balance)
    balances = calculated.map(&:balance)

    assert_equal expected, balances
    assert_equal expected, cash_balances
  end

  # A loan is a special case where despite being a "non-cash" account, it is typical to have "payment" transactions that reduce the loan principal (non cash balance)
  test "loan payment transactions affect non cash balance" do
    skip "TODO: Calculator needs to be updated to support this logic."

    create_opening_anchor_valuation(
      account: @loan,
      balance: 20000, # "Principal balance" (100% non-cash)
      cash_balance: 0, # Loans don't have cash balances
      date: 2.days.ago.to_date
    )

    # "Loan payment" of $2000, which reduces the principal
    # TODO: We'll eventually need to calculate which portion of the txn was "interest" vs. "principal", but for now we'll just assume it's all principal
    # since we don't have a first-class way to track interest payments yet.
    create_transaction(account: @loan, date: 1.day.ago.to_date, amount: -2000)

    expected_cash_balances = [ 0, 0 ]
    expected_balances = [ 20000, 18000 ]
    calculated = Balance::ForwardCalculator.new(@loan).calculate.sort_by(&:date)

    cash_balances = calculated.map(&:cash_balance)
    balances = calculated.map(&:balance)

    assert_equal expected_balances, balances
    assert_equal expected_cash_balances, cash_balances
  end

  # We use Property as a "proxy" for all non-cash accounts (OtherAsset, OtherLiability, Vehicle, Property)
  test "non cash accounts can only use valuations and transactions will be recorded but ignored for balance calculation" do
    skip "TODO: Calculator needs to be updated to support this logic."

    create_opening_anchor_valuation(account: @property, balance: 500000, cash_balance: 0, date: 3.days.ago.to_date)

    # This simulates a "down payment", where even though the user wants to see this transaction in the account, it shouldn't affect
    # the "opening" balance that we set as the "purchase price" of the property.
    create_transaction(account: @property, date: 2.days.ago.to_date, amount: -50000)

    expected_cash_balances = [ 0, 0  ]
    expected_balances = [ 500000, 500000 ]

    calculated = Balance::ForwardCalculator.new(@property).calculate.sort_by(&:date)

    assert_equal expected_cash_balances, calculated.map(&:cash_balance)
    assert_equal expected_balances, calculated.map(&:balance)
  end

  # ------------------------------------------------------------------------------------------------
  # Hybrid accounts (Investment, Crypto) - these have both cash and non-cash balance components
  # ------------------------------------------------------------------------------------------------

  # A transaction increases/decreases cash balance (i.e. "deposits" and "withdrawals")
  # A trade increases/decreases cash balance (i.e. "buys" and "sells", which consume/add "brokerage cash" and create/destroy "holdings")
  # A valuation can set both cash and non-cash balances to "override" investment account value.
  # Holdings are calculated separately and fed into the balance calculator; treated as "non-cash"
  test "investment account calculates balance from transactions and trades and treats holdings as non-cash, additive to balance" do
    aapl = securities(:aapl)

    # Account starts with brokerage cash of $5000 and no holdings
    create_opening_anchor_valuation(account: @investment, balance: 5000, cash_balance: 5000, date: 3.days.ago.to_date)

    # Share purchase reduces cash balance by $1000, but keeps overall balance same
    create_trade(aapl, account: @investment, qty: 10, date: 1.day.ago.to_date, price: 100)

    # Holdings calculator will calculate $1000 worth of holdings
    Holding.create!(date: 1.day.ago.to_date, account: @investment, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")
    Holding.create!(date: Date.current, account: @investment, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")

    # Given constant prices, overall balance (account value) should be constant
    # (the single trade doesn't affect balance; it just alters cash vs. holdings composition)
    expected_cash_balances = [ 5000, 5000, 4000, 4000 ]
    expected_balances = [ 5000, 5000, 5000, 5000 ]

    calculated = Balance::ForwardCalculator.new(@investment).calculate.sort_by(&:date)

    cash_balances = calculated.map(&:cash_balance)
    balances = calculated.map(&:balance)

    assert_equal expected_balances, balances
    assert_equal expected_cash_balances, cash_balances
  end

  # A scenario where the user has set the opening valuation to have a non-zero holdings value, so we need to track that even though it's "unknown" set of holdings.
  test "investment accounts can use valuations to set both cash and non-cash balances" do
    skip "TODO: Calculator needs to be updated to support this logic."

    # Account starts with balance of $17,000, which consists of cash of $5,000 (brokerage cash) and non-cash of $12,000 (holdings value)
    create_opening_anchor_valuation(account: @investment, balance: 17000, cash_balance: 5000, date: 3.days.ago.to_date)

    # A trade increases cash balance by $1000, reduces non-cash balance by $1000 (overall balance stays the same)
    create_trade(securities(:aapl), account: @investment, qty: 10, date: 1.day.ago.to_date, price: 100)

    # In this scenario, our calculated holdings add up to $1,000. This does NOT match the $12,000 in "holdings value" we initialized the account with.
    # In other words, we have $1,000 in "known" holdings, and "$11,000" in "unknown" holdings that the user has told us to track, but hasn't told us details for.
    # Our calculator must respect this "valuation" and still keep the "holdings value" at $12,000, despite the total of holdings only being $1,000.
    Holding.create!(date: 1.day.ago.to_date, account: @investment, security: securities(:aapl), qty: 10, price: 100, amount: 1000, currency: "USD")
    Holding.create!(date: Date.current, account: @investment, security: securities(:aapl), qty: 10, price: 100, amount: 1000, currency: "USD")

    expected_cash_balances = [ 5000, 5000, 4000, 4000 ]
    expected_balances = [ 17000, 17000, 17000, 17000 ] # Balances stay the same

    calculated = Balance::ForwardCalculator.new(@investment).calculate.sort_by(&:date)

    assert_equal expected_cash_balances, calculated.map(&:cash_balance)
    assert_equal expected_balances, calculated.map(&:balance)
  end
end
