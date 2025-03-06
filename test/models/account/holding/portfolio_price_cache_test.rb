require "test_helper"

class Account::Holding::PortfolioPriceCacheTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(
      name: "Test",
      balance: 20000,
      cash_balance: 20000,
      currency: "USD",
      accountable: Investment.new
    )

    @voo = Security.create!(ticker: "VOO", name: "Vanguard S&P 500 ETF")
    Security::Price.create!(security: @voo, date: Date.current, price: 500)
    Security::Price.create!(security: @voo, date: 1.day.ago.to_date, price: 490)

    @wmt = Security.create!(ticker: "WMT", name: "Walmart Inc.")
    Security::Price.create!(security: @wmt, date: Date.current, price: 100)
    Security::Price.create!(security: @wmt, date: 1.day.ago.to_date, price: 100)
  end

  test "initializes with account" do
    cache = Account::Holding::PortfolioPriceCache.new(@account)
    assert_equal @account, cache.instance_variable_get(:@account)
  end
end
