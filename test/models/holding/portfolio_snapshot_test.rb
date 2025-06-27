require "test_helper"

class Holding::PortfolioSnapshotTest < ActiveSupport::TestCase
  include EntriesTestHelper
  setup do
    @account = accounts(:investment)
    @aapl = securities(:aapl)
    @msft = securities(:msft)
  end

  test "captures the most recent holding quantities for each security" do
    # Clear any existing data
    @account.holdings.destroy_all
    @account.entries.destroy_all

    # Create some trades to establish which securities are in the portfolio
    create_trade(@aapl, account: @account, qty: 10, price: 100, date: 5.days.ago)
    create_trade(@msft, account: @account, qty: 30, price: 200, date: 5.days.ago)

    # Create holdings for AAPL at different dates
    @account.holdings.create!(security: @aapl, date: 3.days.ago, qty: 10, price: 100, amount: 1000, currency: "USD")
    @account.holdings.create!(security: @aapl, date: 1.day.ago, qty: 20, price: 150, amount: 3000, currency: "USD")

    # Create holdings for MSFT at different dates
    @account.holdings.create!(security: @msft, date: 5.days.ago, qty: 30, price: 200, amount: 6000, currency: "USD")
    @account.holdings.create!(security: @msft, date: 2.days.ago, qty: 40, price: 250, amount: 10000, currency: "USD")

    snapshot = Holding::PortfolioSnapshot.new(@account)
    portfolio = snapshot.to_h

    assert_equal 2, portfolio.size
    assert_equal 20, portfolio[@aapl.id]
    assert_equal 40, portfolio[@msft.id]
  end

  test "includes securities from trades with zero quantities when no holdings exist" do
    # Clear any existing data
    @account.holdings.destroy_all
    @account.entries.destroy_all

    # Create a trade to establish AAPL is in the portfolio
    create_trade(@aapl, account: @account, qty: 10, price: 100, date: 5.days.ago)

    snapshot = Holding::PortfolioSnapshot.new(@account)
    portfolio = snapshot.to_h

    assert_equal 1, portfolio.size
    assert_equal 0, portfolio[@aapl.id]
  end
end
