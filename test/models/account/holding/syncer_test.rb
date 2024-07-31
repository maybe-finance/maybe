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
      { ticker: "AMZN", qty: 10, price: 214, amount: 10 * 214, date: 2.days.ago.to_date },
      { ticker: "AMZN", qty: 12, price: 215, amount: 12 * 215, date: 1.day.ago.to_date },
      { ticker: "AMZN", qty: 2, price: 216, amount: 2 * 216, date: Date.current },
      { ticker: "NVDA", qty: 20, price: 122, amount: 20 * 122, date: 1.day.ago.to_date },
      { ticker: "NVDA", qty: 20, price: 124, amount: 20 * 124, date: Date.current }
    ]

    run_sync_for(@account)

    assert_holdings(expected)
  end

  test "generates all holdings even when missing security prices" do
    aapl = create_security("AMZN", prices: [
      { date: 1.day.ago.to_date, price: 215 }
    ])

    create_trade(aapl, account: @account, qty: 10, date: 2.days.ago.to_date, price: 210)

    # 2 days ago — no daily price found, but since this is day of entry, we fall back to entry price
    # 1 day ago — finds daily price, uses it
    # Today — no daily price, no entry, so price and amount are `nil`
    expected = [
      { ticker: "AMZN", qty: 10, price: 210, amount: 10 * 210, date: 2.days.ago.to_date },
      { ticker: "AMZN", qty: 10, price: 215, amount: 10 * 215, date: 1.day.ago.to_date },
      { ticker: "AMZN", qty: 10, price: nil, amount: nil, date: Date.current }
    ]

    run_sync_for(@account)

    assert_holdings(expected)
  end

  private

    def assert_holdings(expected_holdings)
      holdings = @account.holdings.includes(:security).to_a
      expected_holdings.each do |expected_holding|
        actual_holding = holdings.find { |holding| holding.security.ticker == expected_holding[:ticker] && holding.date == expected_holding[:date] }
        date = expected_holding[:date]
        expected_price = expected_holding[:price]
        expected_qty = expected_holding[:qty]
        expected_amount = expected_holding[:amount]
        ticker = expected_holding[:ticker]

        assert actual_holding, "expected #{ticker} holding on date: #{date}"
        assert_equal expected_holding[:qty], actual_holding.qty, "expected #{expected_qty} qty for holding #{ticker} on date: #{date}"
        assert_equal expected_holding[:amount], actual_holding.amount, "expected #{expected_amount} amount for holding #{ticker} on date: #{date}"
        assert_equal expected_holding[:price], actual_holding.price, "expected #{expected_price} price for holding #{ticker} on date: #{date}"
      end
    end

    def run_sync_for(account)
      Account::Holding::Syncer.new(account).run
    end
end
