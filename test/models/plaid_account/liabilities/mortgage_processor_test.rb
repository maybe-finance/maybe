require "test_helper"

class PlaidAccount::Liabilities::MortgageProcessorTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)
    @plaid_account.update!(
      plaid_type: "loan",
      plaid_subtype: "mortgage"
    )

    @plaid_account.account.update!(accountable: Loan.new)
  end

  test "updates loan interest rate and type from Plaid data" do
    @plaid_account.update!(raw_liabilities_payload: {
      mortgage: {
        interest_rate: {
          type: "fixed",
          percentage: 4.25
        }
      }
    })

    processor = PlaidAccount::Liabilities::MortgageProcessor.new(@plaid_account)
    processor.process

    loan = @plaid_account.account.loan

    assert_equal "fixed", loan.rate_type
    assert_equal 4.25, loan.interest_rate
  end

  test "does nothing when mortgage data absent" do
    @plaid_account.update!(raw_liabilities_payload: {})

    processor = PlaidAccount::Liabilities::MortgageProcessor.new(@plaid_account)
    processor.process

    loan = @plaid_account.account.loan

    assert_nil loan.rate_type
    assert_nil loan.interest_rate
  end
end
