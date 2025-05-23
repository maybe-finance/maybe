require "test_helper"

class PlaidAccount::Liabilities::StudentLoanProcessorTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)
    @plaid_account.update!(
      plaid_type: "loan",
      plaid_subtype: "student"
    )

    # Change the underlying accountable to a Loan so the helper method `loan` is available
    @plaid_account.account.update!(accountable: Loan.new)
  end

  test "updates loan details including term months from Plaid data" do
    @plaid_account.update!(raw_liabilities_payload: {
      student: {
        interest_rate_percentage: 5.5,
        origination_principal_amount: 20000,
        origination_date: Date.new(2020, 1, 1),
        expected_payoff_date: Date.new(2022, 1, 1)
      }
    })

    processor = PlaidAccount::Liabilities::StudentLoanProcessor.new(@plaid_account)
    processor.process

    loan = @plaid_account.account.loan

    assert_equal "fixed", loan.rate_type
    assert_equal 5.5, loan.interest_rate
    assert_equal 20000, loan.initial_balance
    assert_equal 24, loan.term_months
  end

  test "handles missing payoff dates gracefully" do
    @plaid_account.update!(raw_liabilities_payload: {
      student: {
        interest_rate_percentage: 4.8,
        origination_principal_amount: 15000,
        origination_date: Date.new(2021, 6, 1)
        # expected_payoff_date omitted
      }
    })

    processor = PlaidAccount::Liabilities::StudentLoanProcessor.new(@plaid_account)
    processor.process

    loan = @plaid_account.account.loan

    assert_nil loan.term_months
    assert_equal 4.8, loan.interest_rate
    assert_equal 15000, loan.initial_balance
  end

  test "does nothing when loan data absent" do
    @plaid_account.update!(raw_liabilities_payload: {})

    processor = PlaidAccount::Liabilities::StudentLoanProcessor.new(@plaid_account)
    processor.process

    loan = @plaid_account.account.loan

    assert_nil loan.interest_rate
    assert_nil loan.initial_balance
    assert_nil loan.term_months
  end
end
