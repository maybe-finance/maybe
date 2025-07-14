require "test_helper"

class Balance::TransformerTest < ActiveSupport::TestCase
  setup do
    @checking_account = accounts(:depository)
    @investment_account = accounts(:investment)
    @property_account = accounts(:property)
    @loan_account = accounts(:loan)
    @credit_card = accounts(:credit_card)
  end

  test "apply_valuation splits balance for cash-only accounts (checking, credit cards)" do
    transformer = Balance::Transformer.new(@checking_account)
    valuation = OpenStruct.new(amount: 1000)

    result = transformer.apply_valuation(valuation)

    assert_equal 1000, result.cash_balance
    assert_equal 0, result.non_cash_balance
  end

  # Scenario: Real estate appraiser values your house at $500,000
  # The entire value is non-cash (you can't spend your house like cash)
  test "apply_valuation splits balance for non-cash accounts (property, loans)" do
    transformer = Balance::Transformer.new(@property_account)
    valuation = OpenStruct.new(amount: 500000)

    result = transformer.apply_valuation(valuation)

    assert_equal 0, result.cash_balance
    assert_equal 500000, result.non_cash_balance
  end

  # Scenario: Brokerage statement shows $10,000 total account value
  # We calculate that $7,500 is invested in stocks/ETFs
  # The difference must be uninvested cash sitting in the account
  # Math: $10,000 (total) - $7,500 (holdings) = $2,500 (cash)
  test "apply_valuation calculates brokerage cash for mixed accounts (investments, crypto)" do
    transformer = Balance::Transformer.new(@investment_account)
    valuation = OpenStruct.new(amount: 10000)

    result = transformer.apply_valuation(valuation, non_cash_valuation: 7500)

    assert_equal 2500, result.cash_balance  # $10k total - $7.5k holdings = $2.5k cash
    assert_equal 7500, result.non_cash_balance
  end

  # Scenario: New brokerage account opened with $10,000 deposit
  # No investments purchased yet, so no holdings value provided
  # The entire $10,000 is sitting as cash ready to invest
  # This handles the edge case where we know total value but not holdings
  test "apply_valuation treats mixed accounts as all-cash when no holdings provided" do
    transformer = Balance::Transformer.new(@investment_account)
    valuation = OpenStruct.new(amount: 10000)

    result = transformer.apply_valuation(valuation, non_cash_valuation: nil)

    assert_equal 10000, result.cash_balance
    assert_equal 0, result.non_cash_balance
  end

  # Scenario: Starting with $1,000 in checking, we have $100 expense and $50 deposit today
  # Math: $1,000 (starting) - $100 (expense) + $50 (deposit) = $950 (ending)
  # The positive entry of $100 represents money leaving the account (expense)
  # The negative entry of -$50 represents money entering the account (deposit)
  test "transform applies entries to cash balance for depository accounts" do
    transformer = Balance::Transformer.new(@checking_account)
    entries = [
      OpenStruct.new(amount: 100),   # -$100 (withdrawal)
      OpenStruct.new(amount: -50)    # +$50 (deposit)
    ]

    result = transformer.transform(cash_balance: 1000, non_cash_balance: 0, entries: entries)

    assert_equal 950, result.cash_balance  # $1000 - $100 + $50
    assert_equal 0, result.non_cash_balance
  end

  # Scenario: House worth $500,000, we pay $1,000 property tax from our checking account
  # The property account tracks the house value, not the cash flows related to it
  # So the $1,000 payment doesn't change the property's $500,000 value
  # The payment would be recorded in the checking account, not here
  test "transform ignores entries for property accounts" do
    transformer = Balance::Transformer.new(@property_account)
    entries = [
      OpenStruct.new(amount: 1000)  # This could be property tax payment
    ]

    result = transformer.transform(cash_balance: 0, non_cash_balance: 500000, entries: entries)

    assert_equal 0, result.cash_balance
    assert_equal 500000, result.non_cash_balance
  end

  # Scenario: Loan with $10,000 principal balance, we make a $500 payment
  # Unlike other non-cash accounts, loan payments directly reduce the principal
  # Math: $10,000 (starting principal) - $500 (payment) = $9,500 (ending principal)
  # Note: The negative entry (-$500) represents debt reduction (payment made)
  test "transform applies loan payments to principal balance" do
    transformer = Balance::Transformer.new(@loan_account)
    entries = [
      OpenStruct.new(amount: -500)  # Loan payment (negative = reducing debt)
    ]

    result = transformer.transform(cash_balance: 0, non_cash_balance: 10000, entries: entries)

    assert_equal 0, result.cash_balance
    assert_equal 9500, result.non_cash_balance  # Principal reduced by payment
  end

  # Scenario: Investment account with $1,000 cash and $5,000 in stocks
  # We withdraw $200 cash from the brokerage account
  # Math: $1,000 (cash) - $200 (withdrawal) = $800 (remaining cash)
  # The $5,000 in stocks remains unchanged (only cash is affected by withdrawals)
  test "transform applies entries to cash portion of investment accounts" do
    transformer = Balance::Transformer.new(@investment_account)
    entries = [
      OpenStruct.new(amount: 200)  # Cash withdrawal from brokerage
    ]

    result = transformer.transform(cash_balance: 1000, non_cash_balance: 5000, entries: entries)

    assert_equal 800, result.cash_balance  # Brokerage cash reduced
    assert_equal 5000, result.non_cash_balance  # Holdings unchanged
  end

  # Scenario: Building checking account history forward from yesterday to today
  # Yesterday: $1,000 balance
  # Today: $100 expense transaction
  # Math: $1,000 - $100 = $900 (today's balance)
  # In forward mode, positive entries reduce asset balances (money going out)
  test "forward transformation inverts entry flows for asset accounts" do
    transformer = Balance::Transformer.new(@checking_account, transformation_direction: :forward)
    entries = [
      OpenStruct.new(amount: 100)  # $100 expense
    ]

    result = transformer.transform(cash_balance: 1000, non_cash_balance: 0, entries: entries)

    assert_equal 900, result.cash_balance  # Balance decreased
  end

  # Scenario: Reconstructing yesterday's balance from today's known balance
  # Today: $1,000 balance (known)
  # Today: $100 expense transaction happened
  # Question: What was yesterday's balance?
  # Math: If we spent $100 to get to $1,000, we must have started with $1,100
  # In reverse mode, we ADD the expense back to find the previous balance
  test "reverse transformation preserves entry flows for asset accounts" do
    transformer = Balance::Transformer.new(@checking_account, transformation_direction: :reverse)
    entries = [
      OpenStruct.new(amount: 100)
    ]

    result = transformer.transform(cash_balance: 1000, non_cash_balance: 0, entries: entries)

    assert_equal 1100, result.cash_balance  # Balance increased (going backwards)
  end

  # Scenario: Building loan history forward from yesterday to today
  # Yesterday: $10,000 loan balance
  # Today: $100 new charge/fee added to loan
  # Math: $10,000 + $100 = $10,100 (today's balance)
  # For liabilities, positive entries increase the debt (no negation needed)
  test "forward transformation preserves entry flows for liability accounts" do
    transformer = Balance::Transformer.new(@loan_account, transformation_direction: :forward)
    entries = [
      OpenStruct.new(amount: 100)  # New charges on loan
    ]

    result = transformer.transform(cash_balance: 0, non_cash_balance: 10000, entries: entries)

    assert_equal 10100, result.non_cash_balance  # Debt increased
  end

  # Scenario: Reconstructing yesterday's loan balance from today's known balance
  # Today: $10,000 loan balance (known)
  # Today: $100 charge/fee was added
  # Question: What was yesterday's loan balance?
  # Math: If $100 was added to get to $10,000, we must have started with $9,900
  # In reverse mode for liabilities, we SUBTRACT charges to find previous balance
  test "reverse transformation inverts entry flows for liability accounts" do
    transformer = Balance::Transformer.new(@loan_account, transformation_direction: :reverse)
    entries = [
      OpenStruct.new(amount: 100)
    ]

    result = transformer.transform(cash_balance: 0, non_cash_balance: 10000, entries: entries)

    assert_equal 9900, result.non_cash_balance  # Debt was lower in the past
  end

  test "transform with no entries returns unchanged balances" do
    transformer = Balance::Transformer.new(@checking_account)

    result = transformer.transform(cash_balance: 1000, non_cash_balance: 0, entries: [])

    assert_equal 1000, result.cash_balance
    assert_equal 0, result.non_cash_balance
  end
end
