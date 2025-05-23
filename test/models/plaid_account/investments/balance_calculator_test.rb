require "test_helper"

class PlaidAccount::Investments::BalanceCalculatorTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)

    @plaid_account.update!(
      plaid_type: "investment",
      current_balance: 4000,
      available_balance: 2000 # We ignore this since we have current_balance + holdings
    )
  end

  test "calculates total balance from cash and positions" do
    brokerage_cash_security_id = "plaid_brokerage_cash" # Plaid's brokerage cash security
    cash_equivalent_security_id = "plaid_cash_equivalent" # Cash equivalent security (i.e. money market fund)
    aapl_security_id = "plaid_aapl_security" # Regular stock security

    test_investments = {
      transactions: [], # Irrelevant for balance calcs, leave empty
      holdings: [
        # $1,000 in brokerage cash
        {
          security_id: brokerage_cash_security_id,
          cost_basis: 1000,
          institution_price: 1,
          institution_value: 1000,
          quantity: 1000
        },
        # $1,000 in money market funds
        {
          security_id: cash_equivalent_security_id,
          cost_basis: 1000,
          institution_price: 1,
          institution_value: 1000,
          quantity: 1000
        },
        # $2,000 worth of AAPL stock
        {
          security_id: aapl_security_id,
          cost_basis: 2000,
          institution_price: 200,
          institution_value: 2000,
          quantity: 10
        }
      ],
      securities: [
        {
          security_id: brokerage_cash_security_id,
          ticker_symbol: "CUR:USD",
          is_cash_equivalent: true,
          type: "cash"
        },
        {
          security_id: cash_equivalent_security_id,
          ticker_symbol: "VMFXX", # Vanguard Money Market Reserves
          is_cash_equivalent: true,
          type: "mutual fund"
        },
        {
          security_id: aapl_security_id,
          ticker_symbol: "AAPL",
          is_cash_equivalent: false,
          type: "equity",
          market_identifier_code: "XNAS"
        }
      ]
    }

    @plaid_account.update!(raw_investments_payload: test_investments)

    security_resolver = PlaidAccount::Investments::SecurityResolver.new(@plaid_account)
    balance_calculator = PlaidAccount::Investments::BalanceCalculator.new(@plaid_account, security_resolver: security_resolver)

    # We set this equal to `current_balance`
    assert_equal 4000, balance_calculator.balance

    # This is the sum of "non-brokerage-cash-holdings".  In the above test case, this means
    # we're summing up $2,000 of AAPL + $1,000 Vanguard MM for $3,000 in holdings value.
    # We back this $3,000 from the $4,000 total to get $1,000 in cash balance.
    assert_equal 1000, balance_calculator.cash_balance
  end
end
