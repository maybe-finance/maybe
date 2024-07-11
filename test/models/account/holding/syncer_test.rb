require "test_helper"

class Account::Holding::SyncerTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(name: "Test Brokerage", balance: 20000, currency: "USD", accountable: Investment.new)
  end

  test "account with no trades has no holdings" do
    run_sync_for(@account)

    assert_equal [], @account.holdings
  end

  test "can buy and sell securities" do
    run_sync_for(@account)

    security = create_security("AMZN", prices: [
      { date: 2.days.ago.to_date, price: 214 },
      { date: 1.day.ago.to_date, price: 215 },
      { date: Date.current, price: 216 }
    ])

    create_trade(security, qty: 10, date: 2.days.ago.to_date)
    create_trade(security, qty: 2, date: 1.day.ago.to_date)
    create_trade(security, qty: -10, date: Date.current)

    expected = [
      { symbol: "AMZN", qty: 10, price: 214, amount: 10 * 214, date: 1.day.ago.to_date },
      { symbol: "AMZN", qty: 12, price: 215, amount: 12 * 215, date: 1.day.ago.to_date },
      { symbol: "AMZN", qty: 2, price: 216, amount: 2 * 216, date: Date.current }
    ]

    assert_holdings(expected)
  end

  private

    def assert_holdings(expected_holdings)
      actual = @account.holdings.map do |holding|
        {
          symbol: holding.security.symbol,
          qty: holding.qty,
          price: holding.price,
          amount: holding.amount,
          date: holding.date
        }
      end

      assert_equal expected_holdings, actual
    end

    def create_security(symbol, prices:)
      isin_codes = {
        "AMZN" => "US0231351067"
      }

      isin = isin_codes[symbol]

      prices.each do |price|
        Security::Price.create! isin: isin, date: price[:date], price: price[:price]
      end

      Security.create! isin: isin, symbol: symbol
    end

    def create_trade(security, qty:, date:)
      price = Security::Price.find_by!(isin: security.isin, date: date).price

      trade = Account::Trade.new \
        qty: qty,
        security: security,
        price: price

      @account.entries.create! \
        name: "Trade",
        date: date,
        amount: qty * price,
        currency: "USD",
        entryable: trade
    end

    def run_sync_for(account)
      Account::Holding::Syncer.new(account).run
    end
end
