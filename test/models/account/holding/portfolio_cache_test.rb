require "test_helper"

class Account::Holding::PortfolioCacheTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    # Prices, highest to lowest priority
    @db_price = 210
    @provider_price = 220
    @trade_price = 200
    @holding_price = 250

    @account = families(:empty).accounts.create!(name: "Test Brokerage", balance: 10000, currency: "USD", accountable: Investment.new)
    @test_security = Security.create!(name: "Test Security", ticker: "TEST")

    @trade = create_trade(@test_security, account: @account, qty: 1, date: Date.current, price: @trade_price)
    @holding = Account::Holding.create!(security: @test_security, account: @account, date: Date.current, qty: 1, price: @holding_price, amount: @holding_price, currency: "USD")
    Security::Price.create!(security: @test_security, date: Date.current, price: @db_price)
  end

  test "gets price from DB if available" do
    cache = Account::Holding::PortfolioCache.new(@account)

    assert_equal @db_price, cache.get_price(@test_security.id, Date.current).price
  end

  test "if no price in DB, try fetching from provider" do
    Security::Price.destroy_all
    Security::Price.expects(:find_prices)
                   .with(security: @test_security, start_date: @account.start_date, end_date: Date.current)
                   .returns([
                     Security::Price.new(security: @test_security, date: Date.current, price: @provider_price, currency: "USD")
                   ])

    cache = Account::Holding::PortfolioCache.new(@account)

    assert_equal @provider_price, cache.get_price(@test_security.id, Date.current).price
  end

  test "if no price from db or provider, try getting the price from trades" do
    Security::Price.destroy_all # No DB prices
    Security::Price.expects(:find_prices)
                   .with(security: @test_security, start_date: @account.start_date, end_date: Date.current)
                   .returns([]) # No provider prices

    cache = Account::Holding::PortfolioCache.new(@account)

    assert_equal @trade_price, cache.get_price(@test_security.id, Date.current).price
  end

  test "if no price from db, provider, or trades, search holdings" do
    Security::Price.destroy_all # No DB prices
    Security::Price.expects(:find_prices)
                   .with(security: @test_security, start_date: @account.start_date, end_date: Date.current)
                   .returns([]) # No provider prices

    @account.entries.destroy_all # No prices from trades

    cache = Account::Holding::PortfolioCache.new(@account, use_holdings: true)

    assert_equal @holding_price, cache.get_price(@test_security.id, Date.current).price
  end
end
