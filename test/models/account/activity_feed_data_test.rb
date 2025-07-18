require "test_helper"

class Account::ActivityFeedDataTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:empty)
    @checking = @family.accounts.create!(name: "Test Checking", accountable: Depository.new, currency: "USD", balance: 0)
    @savings = @family.accounts.create!(name: "Test Savings", accountable: Depository.new, currency: "USD", balance: 0)
    @investment = @family.accounts.create!(name: "Test Investment", accountable: Investment.new, currency: "USD", balance: 0)

    @test_period_start = Date.current - 4.days
    @test_period_end = Date.current

    setup_test_data
  end

  test "calculates correct trend for a given date when all balances exist" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    # Trend for day 2 should show change from end of day 1 to end of day 2
    trend = feed_data.trend_for_date(@test_period_start + 1.day)
    assert_equal 1100, trend.current.amount.to_i  # End of day 2
    assert_equal 1000, trend.previous.amount.to_i  # End of day 1
    assert_equal 100, trend.value.amount.to_i
    assert_equal "up", trend.direction.to_s
  end

  test "calculates trend with correct start and end values" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    # First day trend (no previous day balance)
    trend = feed_data.trend_for_date(@test_period_start)
    assert_equal 1000, trend.current.amount.to_i  # End of first day
    assert_equal 0, trend.previous.amount.to_i  # Fallback to 0
    assert_equal 1000, trend.value.amount.to_i
  end

  test "uses last observation carried forward when intermediate balances are missing" do
    @checking.balances.where(date: [ @test_period_start + 1.day, @test_period_start + 3.days ]).destroy_all

    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    # When day 2 balance is missing, both start and end use day 1 balance
    trend = feed_data.trend_for_date(@test_period_start + 1.day)
    assert_equal 1000, trend.current.amount.to_i  # LOCF from day 1
    assert_equal 1000, trend.previous.amount.to_i  # LOCF from day 1
    assert_equal 0, trend.value.amount.to_i
    assert_equal "flat", trend.direction.to_s

    # When day 4 balance is missing, uses last available (day 1)
    trend = feed_data.trend_for_date(@test_period_start + 3.days)
    assert_equal 1000, trend.current.amount.to_i  # LOCF from day 1
    assert_equal 1000, trend.previous.amount.to_i  # LOCF from day 1
  end

  test "returns zero-balance fallback when no prior balances exist" do
    @checking.balances.destroy_all

    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    trend = feed_data.trend_for_date(@test_period_start + 2.days)
    assert_equal 0, trend.current.amount.to_i  # Fallback to 0
    assert_equal 0, trend.previous.amount.to_i  # Fallback to 0
    assert_equal 0, trend.value.amount.to_i
    assert_equal "flat", trend.direction.to_s
  end

  test "identifies transfers for a specific date" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    # Day 2 has the transfer
    transfers = feed_data.transfers_for_date(@test_period_start + 1.day)
    assert_equal 1, transfers.size
    assert_equal @transfer, transfers.first

    # Other days have no transfers
    transfers = feed_data.transfers_for_date(@test_period_start)
    assert_empty transfers
  end

  test "loads exchange rates only for entries with foreign currencies" do
    entries = @investment.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@investment, entries)

    rates = feed_data.exchange_rates_for_date(@test_period_start + 2.days)
    assert_equal 1, rates.size
    assert_equal "EUR", rates.first.from_currency
    assert_equal "USD", rates.first.to_currency
    assert_equal 1.1, rates.first.rate

    rates = feed_data.exchange_rates_for_date(@test_period_start)
    assert_empty rates
  end

  test "returns empty exchange rates when no foreign currency entries exist" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    rates = feed_data.exchange_rates_for_date(@test_period_start + 2.days)
    assert_empty rates
  end

  private

    def setup_test_data
      # Create daily balances for checking account
      5.times do |i|
        date = @test_period_start + i.days
        @checking.balances.create!(
          date: date,
          balance: 1000 + (i * 100),
          currency: "USD"
        )
      end

      # Day 1: Regular transaction
      create_transaction(
        account: @checking,
        date: @test_period_start,
        amount: -50,
        name: "Grocery Store"
      )

      # Day 2: Transfer between accounts
      @transfer = create_transfer(
        from_account: @checking,
        to_account: @savings,
        amount: 200,
        date: @test_period_start + 1.day
      )

      # Day 3: Trade in investment account
      create_trade(
        securities(:aapl),
        account: @investment,
        qty: 10,
        date: @test_period_start + 2.days,
        price: 150
      )

      # Day 3: Foreign currency transaction
      create_transaction(
        account: @investment,
        date: @test_period_start + 2.days,
        amount: -100,
        currency: "EUR",
        name: "International Wire"
      )

      # Create exchange rate for foreign currency
      ExchangeRate.create!(
        date: @test_period_start + 2.days,
        from_currency: "EUR",
        to_currency: "USD",
        rate: 1.1
      )

      # Day 4: Valuation
      create_valuation(
        account: @investment,
        date: @test_period_start + 3.days,
        amount: 25
      )
    end
end
