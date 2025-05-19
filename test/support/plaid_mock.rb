require "ostruct"

# A basic Plaid provider mock that returns static payloads for testing
class PlaidMock
  TransactionSyncResponse = Struct.new(:added, :modified, :removed, :cursor, keyword_init: true)
  InvestmentsResponse      = Struct.new(:holdings, :transactions, :securities, keyword_init: true)

  ITEM = OpenStruct.new(
    item_id: "item_mock_1",
    institution_id: "ins_mock",
    institution_name: "Mock Institution",
    available_products: [],
    billed_products:     %w[transactions investments liabilities]
  )

  INSTITUTION = OpenStruct.new(
    institution_id: "ins_mock",
    institution_name: "Mock Institution"
  )

  ACCOUNTS = [
    OpenStruct.new(
      account_id: "acc_mock_1",
      name:       "Mock Checking",
      mask:       "1111",
      type:       "depository",
      subtype:    "checking",
      balances:   OpenStruct.new(
        current:           1_000.00,
        available:         800.00,
        iso_currency_code: "USD"
      )
    ),
    OpenStruct.new(
      account_id: "acc_mock_2",
      name:       "Mock Brokerage",
      mask:       "2222",
      type:       "investment",
      subtype:    "brokerage",
      balances:   OpenStruct.new(
        current:           15_000.00,
        available:         15_000.00,
        iso_currency_code: "USD"
      )
    )
  ]

  SECURITIES = [
    OpenStruct.new(
      security_id:             "sec_mock_1",
      ticker_symbol:           "AAPL",
      proxy_security_id:       nil,
      market_identifier_code:  "XNAS",
      type:                    "equity",
      is_cash_equivalent:      false
    ),
    # Cash security representation – used to exclude cash-equivalent holdings
    OpenStruct.new(
      security_id:             "sec_mock_cash",
      ticker_symbol:           "CUR:USD",
      proxy_security_id:       nil,
      market_identifier_code:  nil,
      type:                    "cash",
      is_cash_equivalent:      true
    )
  ]

  TRANSACTIONS = [
    OpenStruct.new(
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
    OpenStruct.new(
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
    OpenStruct.new(
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
    OpenStruct.new(
      account_id:              "acc_mock_2",
      security_id:             "sec_mock_1",
      quantity:                10,
      institution_price:       150.00,
      iso_currency_code:       "USD"
    ),
    OpenStruct.new(
      account_id:              "acc_mock_2",
      security_id:             "sec_mock_cash",
      quantity:                200.0,
      institution_price:       1.00,
      iso_currency_code:       "USD"
    )
  ]

  LIABILITIES = {
    credit: [
      OpenStruct.new(
        account_id:              "acc_mock_1",
        minimum_payment_amount:   25.00,
        aprs:                    [ OpenStruct.new(apr_percentage: 19.99) ]
      )
    ],
    mortgage: [
      OpenStruct.new(
        account_id:                  "acc_mock_3",
        origination_principal_amount: 250_000,
        origination_date:             10.years.ago.to_date.to_s,
        interest_rate:               OpenStruct.new(type: "fixed", percentage: 3.5)
      )
    ],
    student: [
      OpenStruct.new(
        account_id:                  "acc_mock_4",
        origination_principal_amount: 50_000,
        origination_date:             6.years.ago.to_date.to_s,
        interest_rate_percentage:    4.0
      )
    ]
  }

  def get_link_token(*, **)
    OpenStruct.new(link_token: "link-mock-123")
  end

  def create_public_token(username: nil)
    "public-mock-#{username || 'user'}"
  end

  def exchange_public_token(_token)
    OpenStruct.new(access_token: "access-mock-123")
  end

  def get_item(_access_token)
    OpenStruct.new(
      item: ITEM
    )
  end

  def get_institution(institution_id)
    OpenStruct.new(
      institution: INSTITUTION
    )
  end

  def get_item_accounts(_item_or_token)
    OpenStruct.new(accounts: ACCOUNTS)
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
    OpenStruct.new(
      credit:   LIABILITIES[:credit],
      mortgage: LIABILITIES[:mortgage],
      student:  LIABILITIES[:student]
    )
  end
end
