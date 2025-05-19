require "ostruct"

# Lightweight wrapper that allows Ostruct objects to properly serialize to JSON
# for storage on PlaidItem / PlaidAccount JSONB columns
class MockData < OpenStruct
  def as_json(options = {})
    @table.as_json(options)
  end
end

# A basic Plaid provider mock that returns static payloads for testing
class PlaidMock
  TransactionSyncResponse = Struct.new(:added, :modified, :removed, :cursor, keyword_init: true)
  InvestmentsResponse      = Struct.new(:holdings, :transactions, :securities, keyword_init: true)

  ITEM = MockData.new(
    item_id: "item_mock_1",
    institution_id: "ins_mock",
    institution_name: "Mock Institution",
    available_products: [],
    billed_products:     %w[transactions investments liabilities]
  )

  INSTITUTION = MockData.new(
    institution_id: "ins_mock",
    institution_name: "Mock Institution"
  )

  ACCOUNTS = [
    MockData.new(
      account_id: "acc_mock_1",
      name:       "Mock Checking",
      mask:       "1111",
      type:       "depository",
      subtype:    "checking",
      balances:   MockData.new(
        current:           1_000.00,
        available:         800.00,
        iso_currency_code: "USD"
      )
    ),
    MockData.new(
      account_id: "acc_mock_2",
      name:       "Mock Brokerage",
      mask:       "2222",
      type:       "investment",
      subtype:    "brokerage",
      balances:   MockData.new(
        current:           15_000.00,
        available:         15_000.00,
        iso_currency_code: "USD"
      )
    )
  ]

  SECURITIES = [
    MockData.new(
      security_id:             "sec_mock_1",
      ticker_symbol:           "AAPL",
      proxy_security_id:       nil,
      market_identifier_code:  "XNAS",
      type:                    "equity",
      is_cash_equivalent:      false
    ),
    # Cash security representation – used to exclude cash-equivalent holdings
    MockData.new(
      security_id:             "sec_mock_cash",
      ticker_symbol:           "CUR:USD",
      proxy_security_id:       nil,
      market_identifier_code:  nil,
      type:                    "cash",
      is_cash_equivalent:      true
    )
  ]

  TRANSACTIONS = [
    MockData.new(
      transaction_id:            "txn_mock_1",
      account_id:                "acc_mock_1",
      merchant_name:             "Mock Coffee",
      original_description:      "MOCK COFFEE SHOP",
      amount:                    4.50,
      iso_currency_code:         "USD",
      date:                      Date.current.to_s,
      personal_finance_category: OpenStruct.new(primary: "FOOD_AND_DRINK", detailed: "COFFEE_SHOP"),
      website:                   "https://coffee.example.com",
      logo_url:                  "https://coffee.example.com/logo.png",
      merchant_entity_id:        "merch_mock_1"
    )
  ]

  INVESTMENT_TRANSACTIONS = [
    MockData.new(
      investment_transaction_id: "inv_txn_mock_1",
      account_id:               "acc_mock_2",
      security_id:              "sec_mock_1",
      type:                     "buy",
      name:                     "BUY AAPL",
      quantity:                 10,
      price:                    150.00,
      amount:                   -1_500.00,
      iso_currency_code:        "USD",
      date:                     Date.current.to_s
    ),
    MockData.new(
      investment_transaction_id: "inv_txn_mock_cash",
      account_id:               "acc_mock_2",
      security_id:              "sec_mock_cash",
      type:                     "cash",
      name:                     "Cash Dividend",
      quantity:                 1,
      price:                    200.00,
      amount:                   200.00,
      iso_currency_code:        "USD",
      date:                     Date.current.to_s
    )
  ]

  HOLDINGS = [
    MockData.new(
      account_id:              "acc_mock_2",
      security_id:             "sec_mock_1",
      quantity:                10,
      institution_price:       150.00,
      iso_currency_code:       "USD"
    ),
    MockData.new(
      account_id:              "acc_mock_2",
      security_id:             "sec_mock_cash",
      quantity:                200.0,
      institution_price:       1.00,
      iso_currency_code:       "USD"
    )
  ]

  LIABILITIES = {
    credit: [
      MockData.new(
        account_id:              "acc_mock_1",
        minimum_payment_amount:   25.00,
        aprs:                    [ MockData.new(apr_percentage: 19.99) ]
      )
    ],
    mortgage: [
      MockData.new(
        account_id:                  "acc_mock_3",
        origination_principal_amount: 250_000,
        origination_date:             10.years.ago.to_date.to_s,
        interest_rate:               MockData.new(type: "fixed", percentage: 3.5)
      )
    ],
    student: [
      MockData.new(
        account_id:                  "acc_mock_4",
        origination_principal_amount: 50_000,
        origination_date:             6.years.ago.to_date.to_s,
        interest_rate_percentage:    4.0
      )
    ]
  }

  def get_link_token(*, **)
    MockData.new(link_token: "link-mock-123")
  end

  def create_public_token(username: nil)
    "public-mock-#{username || 'user'}"
  end

  def exchange_public_token(_token)
    MockData.new(access_token: "access-mock-123")
  end

  def get_item(_access_token)
    MockData.new(
      item: ITEM
    )
  end

  def get_institution(institution_id)
    MockData.new(
      institution: INSTITUTION
    )
  end

  def get_item_accounts(_item_or_token)
    MockData.new(accounts: ACCOUNTS)
  end

  def get_transactions(access_token, next_cursor: nil)
    TransactionSyncResponse.new(
      added:    TRANSACTIONS,
      modified: [],
      removed:  [],
      cursor:   "cursor-mock-1"
    )
  end

  def get_item_investments(_item_or_token, **)
    InvestmentsResponse.new(
      holdings:     HOLDINGS,
      transactions: INVESTMENT_TRANSACTIONS,
      securities:   SECURITIES
    )
  end

  def get_item_liabilities(_item_or_token)
    MockData.new(
      credit:   LIABILITIES[:credit],
      mortgage: LIABILITIES[:mortgage],
      student:  LIABILITIES[:student]
    )
  end
end
