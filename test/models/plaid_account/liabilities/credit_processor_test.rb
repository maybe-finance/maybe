require "test_helper"

class PlaidAccount::Liabilities::CreditProcessorTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)
    @plaid_account.update!(
      plaid_type: "credit",
      plaid_subtype: "credit_card"
    )

    @plaid_account.account.update!(
      accountable: CreditCard.new,
    )
  end

  test "updates credit card minimum payment and APR from Plaid data" do
    @plaid_account.update!(raw_liabilities_payload: {
      credit: {
        minimum_payment_amount: 100,
        aprs: [ { apr_percentage: 15.0 } ]
      }
    })

    processor = PlaidAccount::Liabilities::CreditProcessor.new(@plaid_account)
    processor.process

    assert_equal 100, @plaid_account.account.credit_card.minimum_payment
    assert_equal 15.0, @plaid_account.account.credit_card.apr
  end

  test "does nothing when liability data absent" do
    @plaid_account.update!(raw_liabilities_payload: {})
    processor = PlaidAccount::Liabilities::CreditProcessor.new(@plaid_account)
    processor.process

    assert_nil @plaid_account.account.credit_card.minimum_payment
    assert_nil @plaid_account.account.credit_card.apr
  end
end
