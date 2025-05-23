require "test_helper"

class PlaidAccount::Investments::SecurityResolverTest < ActiveSupport::TestCase
  setup do
    @upstream_resolver = mock("Security::Resolver")
    @plaid_account = plaid_accounts(:one)
    @resolver = PlaidAccount::Investments::SecurityResolver.new(@plaid_account)
  end

  test "handles missing plaid security" do
    missing_id = "missing_security_id"

    # Ensure there are *no* securities that reference the missing ID
    @plaid_account.update!(raw_investments_payload: {
      securities: [
        {
          "security_id" => "some_other_id",
          "ticker_symbol" => "FOO",
          "type" => "equity",
          "market_identifier_code" => "XNAS"
        }
      ]
    })

    Security::Resolver.expects(:new).never
    Sentry.stubs(:capture_exception)

    response = @resolver.resolve(plaid_security_id: missing_id)

    assert_nil response.security
    refute response.cash_equivalent?
    refute response.brokerage_cash?
  end

  test "identifies brokerage cash plaid securities" do
    brokerage_cash_id = "brokerage_cash_security_id"

    @plaid_account.update!(raw_investments_payload: {
      securities: [
        {
          "security_id" => brokerage_cash_id,
          "ticker_symbol" => "CUR:USD", # Plaid brokerage cash ticker
          "type" => "cash",
          "is_cash_equivalent" => true
        }
      ]
    })

    Security::Resolver.expects(:new).never

    response = @resolver.resolve(plaid_security_id: brokerage_cash_id)

    assert_nil response.security
    assert response.cash_equivalent?
    assert response.brokerage_cash?
  end

  test "identifies cash equivalent plaid securities" do
    mmf_security_id = "money_market_security_id"

    @plaid_account.update!(raw_investments_payload: {
      securities: [
        {
          "security_id" => mmf_security_id,
          "ticker_symbol" => "VMFXX", # Vanguard Federal Money Market Fund
          "type" => "mutual fund",
          "is_cash_equivalent" => true,
          "market_identifier_code" => "XNAS"
        }
      ]
    })

    resolved_security = Security.create!(ticker: "VMFXX", exchange_operating_mic: "XNAS")

    Security::Resolver.expects(:new)
                     .with("VMFXX", exchange_operating_mic: "XNAS")
                     .returns(@upstream_resolver)
    @upstream_resolver.expects(:resolve).returns(resolved_security)

    response = @resolver.resolve(plaid_security_id: mmf_security_id)

    assert_equal resolved_security, response.security
    assert response.cash_equivalent?
    refute response.brokerage_cash?
  end

  test "resolves normal plaid securities" do
    security_id = "regular_security_id"

    @plaid_account.update!(raw_investments_payload: {
      securities: [
        {
          "security_id" => security_id,
          "ticker_symbol" => "IVV",
          "type" => "etf",
          "is_cash_equivalent" => false,
          "market_identifier_code" => "XNAS"
        }
      ]
    })

    resolved_security = Security.create!(ticker: "IVV", exchange_operating_mic: "XNAS")

    Security::Resolver.expects(:new)
                     .with("IVV", exchange_operating_mic: "XNAS")
                     .returns(@upstream_resolver)
    @upstream_resolver.expects(:resolve).returns(resolved_security)

    response = @resolver.resolve(plaid_security_id: security_id)

    assert_equal resolved_security, response.security
    refute response.cash_equivalent? # Normal securities are not cash equivalent
    refute response.brokerage_cash?
  end
end
