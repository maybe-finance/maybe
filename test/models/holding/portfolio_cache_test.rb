require "test_helper"

class Holding::PortfolioCacheTest < ActiveSupport::TestCase
  include EntriesTestHelper, ProviderTestHelper

  setup do
    @provider = mock
    Security.stubs(:provider).returns(@provider)

    @account = families(:empty).accounts.create!(
      name: "Test Brokerage",
      balance: 10000,
      currency: "USD",
      accountable: Investment.new
    )

    @security = Security.create!(name: "Test Security", ticker: "TEST", exchange_operating_mic: "TEST")

    @trade = create_trade(@security, account: @account, qty: 1, date: 2.days.ago.to_date, price: 210.23).trade
  end

  test "gets price from DB if available" do
    db_price = 210

    Security::Price.create!(
      security: @security,
      date: Date.current,
      price: db_price
    )

    expect_provider_prices([], start_date: @account.start_date)

    cache = Holding::PortfolioCache.new(@account)
    assert_equal db_price, cache.get_price(@security.id, Date.current).price
  end

  test "if no price in DB, try fetching from provider" do
    Security::Price.delete_all

    provider_price = Security::Price.new(
      security: @security,
      date: Date.current,
      price: 220,
      currency: "USD"
    )

    expect_provider_prices([ provider_price ], start_date: @account.start_date)

    cache = Holding::PortfolioCache.new(@account)
    assert_equal provider_price.price, cache.get_price(@security.id, Date.current).price
  end

  test "if no price from db or provider, try getting the price from trades" do
    Security::Price.destroy_all
    expect_provider_prices([], start_date: @account.start_date)

    cache = Holding::PortfolioCache.new(@account)
    assert_equal @trade.price, cache.get_price(@security.id, @trade.entry.date).price
  end

  test "if no price from db, provider, or trades, search holdings" do
    Security::Price.delete_all
    Entry.delete_all

    holding = Holding.create!(
      security: @security,
      account: @account,
      date: Date.current,
      qty: 1,
      price: 250,
      amount: 250 * 1,
      currency: "USD"
    )

    expect_provider_prices([], start_date: @account.start_date)

    cache = Holding::PortfolioCache.new(@account, use_holdings: true)
    assert_equal holding.price, cache.get_price(@security.id, holding.date).price
  end

  private
    def expect_provider_prices(prices, start_date:, end_date: Date.current)
      @provider.expects(:fetch_security_prices)
               .with(@security, start_date: start_date, end_date: end_date)
               .returns(provider_success_response(prices))
    end
end
