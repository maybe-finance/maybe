require "ostruct"

module PlaidTestHelper
  PLAID_TEST_ACCOUNT_ID = "plaid_test_account_id"
  PLAID_TEST_CASH_SECURITY_ID = "plaid_test_cash_security_id"

  # Special case
  def create_plaid_cash_security(attributes = {})
    default_attributes = {
      close_price: nil,
      close_price_as_of: nil,
      cusip: nil,
      fixed_income: nil,
      industry: nil,
      institution_id: nil,
      institution_security_id: nil,
      is_cash_equivalent: false, # Plaid sometimes returns false here (bad data), so we should not rely on it
      isin: nil,
      iso_currency_code: "USD",
      market_identifier_code: nil,
      name: "US Dollar",
      option_contract: nil,
      proxy_security_id: nil,
      sector: nil,
      security_id: PLAID_TEST_CASH_SECURITY_ID,
      sedol: nil,
      ticker_symbol: "CUR:USD",
      type: "cash",
      unofficial_currency_code: nil,
      update_datetime: nil
    }

    OpenStruct.new(
      default_attributes.merge(attributes)
    )
  end

  def create_plaid_security(attributes = {})
    default_attributes = {
      close_price: 606.71,
      close_price_as_of: Date.current,
      cusip: nil,
      fixed_income: nil,
      industry: "Mutual Funds",
      institution_id: nil,
      institution_security_id: nil,
      is_cash_equivalent: false,
      isin: nil,
      iso_currency_code: "USD",
      market_identifier_code: "XNAS",
      name: "iShares S&P 500 Index",
      option_contract: nil,
      proxy_security_id: nil,
      sector: "Financial",
      security_id: "plaid_test_security_id",
      sedol: "2593025",
      ticker_symbol: "IVV",
      type: "etf",
      unofficial_currency_code: nil,
      update_datetime: nil
    }

    OpenStruct.new(
      default_attributes.merge(attributes)
    )
  end

  def create_plaid_cash_holding(attributes = {})
    default_attributes = {
      account_id: PLAID_TEST_ACCOUNT_ID,
      cost_basis: 1000,
      institution_price: 1,
      institution_price_as_of: Date.current,
      iso_currency_code: "USD",
      quantity: 1000,
      security_id: PLAID_TEST_CASH_SECURITY_ID,
      unofficial_currency_code: nil,
      vested_quantity: nil,
      vested_value: nil
    }

    OpenStruct.new(
      default_attributes.merge(attributes)
    )
  end

  def create_plaid_holding(attributes = {})
    default_attributes = {
      account_id: PLAID_TEST_ACCOUNT_ID,
      cost_basis: 2000,
      institution_price: 200,
      institution_price_as_of: Date.current,
      iso_currency_code: "USD",
      quantity: 10,
      security_id: "plaid_test_security_id",
      unofficial_currency_code: nil,
      vested_quantity: nil,
      vested_value: nil
    }

    OpenStruct.new(
      default_attributes.merge(attributes)
    )
  end

  def create_plaid_investment_transaction(attributes = {})
    default_attributes = {
      account_id: PLAID_TEST_ACCOUNT_ID,
      amount: 500,
      cancel_transaction_id: nil,
      date: 5.days.ago.to_date,
      fees: 0,
      investment_transaction_id: "plaid_test_investment_transaction_id",
      iso_currency_code: "USD",
      name: "Buy 100 shares of IVV",
      price: 606.71,
      quantity: 100,
      security_id: "plaid_test_security_id",
      type: "buy",
      subtype: "buy",
      unofficial_currency_code: nil
    }

    OpenStruct.new(
      default_attributes.merge(attributes)
    )
  end
end
