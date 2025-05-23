require "test_helper"

class PlaidAccount::Investments::HoldingsProcessorTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)
    @security_resolver = PlaidAccount::Investments::SecurityResolver.new(@plaid_account)
  end

  test "creates holding records from Plaid holdings snapshot" do
    test_investments_payload = {
      securities: [], # mocked
      holdings: [
        {
          "security_id" => "123",
          "quantity" => 100,
          "institution_price" => 100,
          "iso_currency_code" => "USD"
        }
      ],
      transactions: [] # not relevant for test
    }

    @plaid_account.update!(raw_investments_payload: test_investments_payload)

    @security_resolver.expects(:resolve)
                      .with(plaid_security_id: "123")
                      .returns(
                        OpenStruct.new(
                          security: securities(:aapl),
                          cash_equivalent?: false,
                          brokerage_cash?: false
                        )
                      )

    processor = PlaidAccount::Investments::HoldingsProcessor.new(@plaid_account, security_resolver: @security_resolver)

    assert_difference "Holding.count" do
      processor.process
    end

    holding = Holding.order(created_at: :desc).first

    assert_equal 100, holding.qty
    assert_equal 100, holding.price
    assert_equal "USD", holding.currency
    assert_equal securities(:aapl), holding.security
    assert_equal Date.current, holding.date
  end
end
