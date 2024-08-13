require "test_helper"

class Account::Holding::SyncerTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper, SecuritiesTestHelper

  setup do
    @account = families(:empty).accounts.create!(name: "Test Brokerage", balance: 20000, currency: "USD", accountable: Investment.new)
  end

  test "account with no trades has no holdings" do
    run_sync_for(@account)

    assert_equal [], @account.holdings
  end

  test "can buy and sell securities" do
    security1 = create_security("AMZN", prices: [
      { date: 2.days.ago.to_date, price: 214 },
      { date: 1.day.ago.to_date, price: 215 },
      { date: Date.current, price: 216 }
    ])

    security2 = create_security("NVDA", prices: [
      { date: 1.day.ago.to_date, price: 122 },
      { date: Date.current, price: 124 }
    ])

    create_trade(security1, account: @account, qty: 10, date: 2.days.ago.to_date) # buy 10 shares of AMZN

    create_trade(security1, account: @account, qty: 2, date: 1.day.ago.to_date) # buy 2 shares of AMZN
    create_trade(security2, account: @account, qty: 20, date: 1.day.ago.to_date) # buy 20 shares of NVDA

    create_trade(security1, account: @account, qty: -10, date: Date.current) # sell 10 shares of AMZN

    expected = [
      { ticker: "AMZN", qty: 10, price: 214, amount: 10 * 214, date: 2.days.ago.to_date, currency: "USD" },
      { ticker: "AMZN", qty: 12, price: 215, amount: 12 * 215, date: 1.day.ago.to_date, currency: "USD" },
      { ticker: "AMZN", qty: 2, price: 216, amount: 2 * 216, date: Date.current, currency: "USD" },
      { ticker: "NVDA", qty: 20, price: 122, amount: 20 * 122, date: 1.day.ago.to_date, currency: "USD" },
      { ticker: "NVDA", qty: 20, price: 124, amount: 20 * 124, date: Date.current, currency: "USD" }
    ]

    run_sync_for(@account)

    assert_holdings(expected, @account)
  end

  test "generates holdings with prices" do
    provider = mock
    Security::Price.stubs(:security_prices_provider).returns(provider)

    provider.expects(:fetch_security_prices).never

    amzn = create_security("AMZN", prices: [ { date: Date.current, price: 215 } ])
    create_trade(amzn, account: @account, qty: 10, date: Date.current, price: 215)

    expected = [
      { ticker: "AMZN", qty: 10, price: 215, amount: 10 * 215, date: Date.current, currency: "USD" }
    ]

    run_sync_for(@account)

    assert_holdings(expected, @account)
  end

  test "generates all holdings even when missing security prices" do
    amzn = create_security("AMZN", prices: [])

    create_trade(amzn, account: @account, qty: 10, date: 2.days.ago.to_date, price: 210)

    # 2 days ago — no daily price found, but since this is day of entry, we fall back to entry price
    # 1 day ago — finds daily price, uses it
    # Today — no daily price, no entry, so price and amount are `nil`
    expected = [
      { ticker: "AMZN", qty: 10, price: 210, amount: 10 * 210, date: 2.days.ago.to_date, currency: "USD" },
      { ticker: "AMZN", qty: 10, price: 215, amount: 10 * 215, date: 1.day.ago.to_date, currency: "USD" },
      { ticker: "AMZN", qty: 10, price: nil, amount: nil, date: Date.current, currency: "USD" }
    ]

    Security::Price.expects(:find_prices)
                   .with(start_date: 2.days.ago.to_date, end_date: Date.current, ticker: "AMZN")
                   .once
                   .returns([
                              Security::Price.new(ticker: "AMZN", date: 1.day.ago.to_date, price: 215)
                            ])

    run_sync_for(@account)

    assert_holdings(expected, @account)
  end

  # TODO
  test "syncs multi currency trade" do
    price_currency = "USD" # Stock price fetched from provider is USD
    trade_currency = "EUR" # Trade performed in EUR

    amzn = create_security("AMZN", prices: [
      { date: 1.day.ago.to_date, price: 200, currency: price_currency },
      { date: Date.current, price: 210, currency: price_currency }
    ])

    create_trade(amzn, account: @account, qty: 10, date: 1.day.ago.to_date, price: 180, currency: trade_currency)

    # We expect holding to be generated in the account's currency (which is what shows to the user)
    expected = [
      { ticker: "AMZN", qty: 10, price: 200, amount: 10 * 200, date: 1.day.ago.to_date, currency: "USD" },
      { ticker: "AMZN", qty: 10, price: 210, amount: 10 * 210, date: Date.current, currency: "USD" }
    ]

    run_sync_for(@account)

    assert_holdings(expected, @account)
  end

  # TODO
  test "syncs foreign currency investment account" do
    # Account is EUR, but family is USD.  Must show holdings on account page in EUR, but aggregate holdings in USD for family views
    @account.update! currency: "EUR"
    assert_not_equal @account.currency, @account.family.currency

    price_currency = "USD" # Stock price fetched from provider is USD
    trade_currency = "EUR" # Trade performed in EUR

    amzn = create_security("AMZN", prices: [
      { date: 1.day.ago.to_date, price: 200, currency: price_currency },
      { date: Date.current, price: 210, currency: price_currency }
    ])

    create_trade(amzn, account: @account, qty: 10, date: 1.day.ago.to_date, price: 200, currency: trade_currency)

    ExchangeRate.create! date: 1.day.ago.to_date, from_currency: "USD", to_currency: "EUR", rate: 0.9
    ExchangeRate.create! date: Date.current, from_currency: "USD", to_currency: "EUR", rate: 0.9

    expected = [
      # Holdings in the account's currency for the account view
      { ticker: "AMZN", qty: 10, price: 200 * 0.9, amount: 10 * 200 * 0.9, date: 1.day.ago.to_date, currency: "EUR" },
      { ticker: "AMZN", qty: 10, price: 200 * 0.9, amount: 10 * 200 * 0.9, date: Date.current, currency: "EUR" },

      # Holdings in the family's currency for aggregated calculations
      { ticker: "AMZN", qty: 10, price: 200, amount: 10 * 200, date: 1.day.ago.to_date, currency: "USD" },
      { ticker: "AMZN", qty: 10, price: 200, amount: 10 * 200, date: Date.current, currency: "USD" }
    ]

    run_sync_for(@account)

    assert_holdings(expected, @account)
  end

  private

    def assert_holdings(expected_holdings, account)
      holdings = account.holdings.includes(:security).to_a
      expected_holdings.each do |expected_holding|
        actual_holding = holdings.find { |holding| holding.security.ticker == expected_holding[:ticker] && holding.date == expected_holding[:date] }
        date = expected_holding[:date]
        expected_price = expected_holding[:price].to_d
        expected_qty = expected_holding[:qty]
        expected_amount = expected_holding[:amount].to_d
        expected_currency = expected_holding[:currency]
        ticker = expected_holding[:ticker]

        assert actual_holding, "expected #{ticker} holding on date: #{date}"
        assert_equal expected_qty, actual_holding.qty, "expected #{expected_qty} qty for holding #{ticker} on date: #{date}"
        assert_equal expected_amount, actual_holding.amount.to_d, "expected #{expected_amount} amount for holding #{ticker} on date: #{date}"
        assert_equal expected_price, actual_holding.price.to_d, "expected #{expected_price} price for holding #{ticker} on date: #{date}"
        assert_equal expected_currency, actual_holding.currency, "expected #{expected_currency} price for holding #{ticker} on date: #{date}"
      end
    end

    def run_sync_for(account)
      Account::Holding::Syncer.new(account).run
    end
end
