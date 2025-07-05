require "test_helper"

class Balance::SyncCacheTest < ActiveSupport::TestCase
  include EntriesTestHelper
  include ExchangeRateTestHelper

  setup do
    @account = families(:empty).accounts.create!(
      name: "Test",
      balance: 20000,
      cash_balance: 20000,
      currency: "USD",
      accountable: Investment.new
    )
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: 100, currency: "CAD")
    @sync_cache = Balance::SyncCache.new(@account)
  end

  test "convert currency when rate available by cache" do
    load_exchange_prices
    money = Money.new(100, "CAD")
    converted_money = nil
    assert_queries_count(3) do
      converted_money = @sync_cache.find_rate_by_cache(money, @account.currency, date: 1.day.ago.to_date)
    end
    expected_money = money.exchange_to(@account.currency, date: 1.day.ago.to_date)

    assert_equal expected_money.amount, converted_money.amount
    assert_equal expected_money.currency, converted_money.currency
  end

  test "convert currency after fetching rate" do
    ExchangeRate.expects(:fetch_rate).returns(Provider::ExchangeRateConcept::Rate.new(date: 1.day.ago.to_date, from: "JPY", to: "USD", rate: 0.007))
    money = Money.new(1000, "JPY")

    assert_equal Money.new(7, "USD"), @sync_cache.find_rate_by_cache(money, @account.currency, date: 1.day.ago.to_date)
  end

  test "converts currency with a fallback rate" do
    ExchangeRate.expects(:fetch_rate).returns(nil).twice
    money = Money.new(1000, "CAD")

    assert_queries_count(3) do
      assert_equal Money.new(0, "USD"), @sync_cache.find_rate_by_cache(money, @account.currency, date: 1.day.ago.to_date, fallback_rate: 0)
    end

    assert_equal Money.new(1000, "USD"), @sync_cache.find_rate_by_cache(money, @account.currency, date: 1.day.ago.to_date, fallback_rate: 1)
  end

  test "raises when no conversion rate available and no fallback rate provided" do
    money = Money.new(1000, "JPY")
    ExchangeRate.expects(:fetch_rate).returns(nil)

    assert_raises Money::ConversionError do
      @sync_cache.find_rate_by_cache(money, @account.currency, date: 1.day.ago.to_date, fallback_rate: nil)
    end
  end

  test "raises if input is not Money-like" do
    assert_raises(TypeError) do
      @sync_cache.find_rate_by_cache(12345, "USD")
    end
  end

  test "returns original money when source and target currency are the same" do
    money = Money.new(500, "USD")
    result = nil
    assert_queries_count(0) do
      result = @sync_cache.find_rate_by_cache(money, "USD", date: Date.today)
    end
    assert_same money, result
  end

  test "query and cache exchange rates" do
    load_exchange_prices
    assert_queries_count(3) do
      @sync_cache.find_rate_by_cache(Money.new(100, "CAD"), @account.currency, date: 1.day.ago.to_date)
    end

    assert_queries_count(0) do
      @sync_cache.find_rate_by_cache(Money.new(100, "CAD"), @account.currency, date: 1.day.ago.to_date)
      @sync_cache.find_rate_by_cache(Money.new(200, "CAD"), @account.currency, date: 1.day.ago.to_date)
    end
  end
end
