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
          "iso_currency_code" => "USD",
          "institution_price_as_of" => 1.day.ago.to_date
        },
        {
          "security_id" => "456",
          "quantity" => 200,
          "institution_price" => 200,
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

    @security_resolver.expects(:resolve)
                      .with(plaid_security_id: "456")
                      .returns(
                        OpenStruct.new(
                          security: securities(:aapl),
                          cash_equivalent?: false,
                          brokerage_cash?: false
                        )
                      )

    processor = PlaidAccount::Investments::HoldingsProcessor.new(@plaid_account, security_resolver: @security_resolver)

    assert_difference "Holding.count", 2 do
      processor.process
    end

    holdings = Holding.where(account: @plaid_account.account).order(:date)

    assert_equal 100, holdings.first.qty
    assert_equal 100, holdings.first.price
    assert_equal "USD", holdings.first.currency
    assert_equal securities(:aapl), holdings.first.security
    assert_equal 1.day.ago.to_date, holdings.first.date

    assert_equal 200, holdings.second.qty
    assert_equal 200, holdings.second.price
    assert_equal "USD", holdings.second.currency
    assert_equal securities(:aapl), holdings.second.security
    assert_equal Date.current, holdings.second.date
  end

  # When Plaid provides holdings data, it includes an "institution_price_as_of" date
  # which represents when the holdings were last updated. Any holdings in our database
  # after this date are now stale and should be deleted, as the Plaid data is the
  # authoritative source of truth for the current holdings.
  test "deletes stale holdings per security based on institution price date" do
    account = @plaid_account.account

    # Create a third security for testing
    third_security = Security.create!(ticker: "GOOGL", name: "Google", exchange_operating_mic: "XNAS", country_code: "US")

    # Scenario 3: AAPL has a stale holding that should be deleted
    stale_aapl_holding = account.holdings.create!(
      security: securities(:aapl),
      date: Date.current,
      qty: 80,
      price: 180,
      amount: 14400,
      currency: "USD"
    )

    # Plaid returns 3 holdings with different scenarios
    test_investments_payload = {
      securities: [],
      holdings: [
        # Scenario 1: Current date holding (no deletions needed)
        {
          "security_id" => "current",
          "quantity" => 50,
          "institution_price" => 50,
          "iso_currency_code" => "USD",
          "institution_price_as_of" => Date.current
        },
        # Scenario 2: Yesterday's holding with no future holdings
        {
          "security_id" => "clean",
          "quantity" => 75,
          "institution_price" => 75,
          "iso_currency_code" => "USD",
          "institution_price_as_of" => 1.day.ago.to_date
        },
        # Scenario 3: Yesterday's holding with stale future holding
        {
          "security_id" => "stale",
          "quantity" => 100,
          "institution_price" => 100,
          "iso_currency_code" => "USD",
          "institution_price_as_of" => 1.day.ago.to_date
        }
      ],
      transactions: []
    }

    @plaid_account.update!(raw_investments_payload: test_investments_payload)

    # Mock security resolver for all three securities
    @security_resolver.expects(:resolve)
                      .with(plaid_security_id: "current")
                      .returns(OpenStruct.new(security: securities(:msft), cash_equivalent?: false, brokerage_cash?: false))

    @security_resolver.expects(:resolve)
                      .with(plaid_security_id: "clean")
                      .returns(OpenStruct.new(security: third_security, cash_equivalent?: false, brokerage_cash?: false))

    @security_resolver.expects(:resolve)
                      .with(plaid_security_id: "stale")
                      .returns(OpenStruct.new(security: securities(:aapl), cash_equivalent?: false, brokerage_cash?: false))

    processor = PlaidAccount::Investments::HoldingsProcessor.new(@plaid_account, security_resolver: @security_resolver)
    processor.process

    # Should have created 3 new holdings
    assert_equal 3, account.holdings.count

    # Scenario 3: Should have deleted the stale AAPL holding
    assert_not account.holdings.exists?(stale_aapl_holding.id)

    # Should have the correct holdings from Plaid
    assert account.holdings.exists?(security: securities(:msft), date: Date.current, qty: 50)
    assert account.holdings.exists?(security: third_security, date: 1.day.ago.to_date, qty: 75)
    assert account.holdings.exists?(security: securities(:aapl), date: 1.day.ago.to_date, qty: 100)
  end

  test "continues processing other holdings when security resolution fails" do
    test_investments_payload = {
      securities: [],
      holdings: [
        {
          "security_id" => "fail",
          "quantity" => 100,
          "institution_price" => 100,
          "iso_currency_code" => "USD"
        },
        {
          "security_id" => "success",
          "quantity" => 200,
          "institution_price" => 200,
          "iso_currency_code" => "USD"
        }
      ],
      transactions: []
    }

    @plaid_account.update!(raw_investments_payload: test_investments_payload)

    # First security fails to resolve
    @security_resolver.expects(:resolve)
                      .with(plaid_security_id: "fail")
                      .returns(OpenStruct.new(security: nil))

    # Second security succeeds
    @security_resolver.expects(:resolve)
                      .with(plaid_security_id: "success")
                      .returns(OpenStruct.new(security: securities(:aapl)))

    processor = PlaidAccount::Investments::HoldingsProcessor.new(@plaid_account, security_resolver: @security_resolver)

    # Should create only 1 holding (the successful one)
    assert_difference "Holding.count", 1 do
      processor.process
    end

    # Should have created the successful holding
    assert @plaid_account.account.holdings.exists?(security: securities(:aapl), qty: 200)
  end
end
