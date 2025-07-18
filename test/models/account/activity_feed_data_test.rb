require "test_helper"

class Account::ActivityFeedDataTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:empty)
    @checking = @family.accounts.create!(name: "Test Checking", accountable: Depository.new, currency: "USD", balance: 0)
    @savings = @family.accounts.create!(name: "Test Savings", accountable: Depository.new, currency: "USD", balance: 0)
    @investment = @family.accounts.create!(name: "Test Investment", accountable: Investment.new, currency: "USD", balance: 0)

    @test_period_start = Date.current - 4.days

    setup_test_data
  end

  test "calculates balance trend with complete balance history" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date
    day2_activity = find_activity_for_date(activities, @test_period_start + 1.day)

    assert_not_nil day2_activity
    trend = day2_activity.balance_trend
    assert_equal 1100, trend.current.amount.to_i  # End of day 2
    assert_equal 1000, trend.previous.amount.to_i  # End of day 1
    assert_equal 100, trend.value.amount.to_i
    assert_equal "up", trend.direction.to_s
  end

  test "calculates balance trend for first day with zero starting balance" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date
    day1_activity = find_activity_for_date(activities, @test_period_start)

    assert_not_nil day1_activity
    trend = day1_activity.balance_trend
    assert_equal 1000, trend.current.amount.to_i  # End of first day
    assert_equal 0, trend.previous.amount.to_i  # Fallback to 0
    assert_equal 1000, trend.value.amount.to_i
  end

  test "uses last observed balance when intermediate balances are missing" do
    @checking.balances.where(date: [ @test_period_start + 1.day, @test_period_start + 3.days ]).destroy_all

    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date

    # When day 2 balance is missing, both start and end use day 1 balance
    day2_activity = find_activity_for_date(activities, @test_period_start + 1.day)
    assert_not_nil day2_activity
    trend = day2_activity.balance_trend
    assert_equal 1000, trend.current.amount.to_i  # LOCF from day 1
    assert_equal 1000, trend.previous.amount.to_i  # LOCF from day 1
    assert_equal 0, trend.value.amount.to_i
    assert_equal "flat", trend.direction.to_s
  end

  test "returns zero balance when no balance history exists" do
    @checking.balances.destroy_all

    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date
    # Use first day which has a transaction
    day1_activity = find_activity_for_date(activities, @test_period_start)

    assert_not_nil day1_activity
    trend = day1_activity.balance_trend
    assert_equal 0, trend.current.amount.to_i  # Fallback to 0
    assert_equal 0, trend.previous.amount.to_i  # Fallback to 0
    assert_equal 0, trend.value.amount.to_i
    assert_equal "flat", trend.direction.to_s
  end

  test "calculates cash and holdings trends for investment accounts" do
    entries = @investment.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@investment, entries)

    activities = feed_data.entries_by_date
    day3_activity = find_activity_for_date(activities, @test_period_start + 2.days)

    assert_not_nil day3_activity

    # Cash trend for day 3 (after foreign currency transaction)
    cash_trend = day3_activity.cash_balance_trend
    assert_equal 400, cash_trend.current.amount.to_i  # End of day 3 cash balance
    assert_equal 500, cash_trend.previous.amount.to_i  # End of day 2 cash balance
    assert_equal(-100, cash_trend.value.amount.to_i)
    assert_equal "down", cash_trend.direction.to_s

    # Holdings trend for day 3 (after trade)
    holdings_trend = day3_activity.holdings_value_trend
    assert_equal 1500, holdings_trend.current.amount.to_i  # Total balance - cash balance
    assert_equal 0, holdings_trend.previous.amount.to_i  # No holdings before trade
    assert_equal 1500, holdings_trend.value.amount.to_i
    assert_equal "up", holdings_trend.direction.to_s
  end

  test "identifies transfers for a specific date" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date

    # Day 2 has the transfer
    day2_activity = find_activity_for_date(activities, @test_period_start + 1.day)
    assert_not_nil day2_activity
    assert_equal 1, day2_activity.transfers.size
    assert_equal @transfer, day2_activity.transfers.first

    # Other days have no transfers
    day1_activity = find_activity_for_date(activities, @test_period_start)
    assert_not_nil day1_activity
    assert_empty day1_activity.transfers
  end

  test "returns complete ActivityDateData objects with all required fields" do
    entries = @investment.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@investment, entries)

    activities = feed_data.entries_by_date

    # Check that we get ActivityDateData objects
    assert activities.all? { |a| a.is_a?(Account::ActivityFeedData::ActivityDateData) }

    # Check that each ActivityDate has the required fields
    activities.each do |activity|
      assert_respond_to activity, :date
      assert_respond_to activity, :entries
      assert_respond_to activity, :balance_trend
      assert_respond_to activity, :cash_balance_trend
      assert_respond_to activity, :holdings_value_trend
      assert_respond_to activity, :transfers
    end
  end

  test "handles valuations correctly by summing entry changes" do
    # Create account with known balances
    account = @family.accounts.create!(name: "Test Investment", accountable: Investment.new, currency: "USD", balance: 0)

    # Day 1: Starting balance
    account.balances.create!(
      date: @test_period_start,
      balance: 7321.56,
      cash_balance: 1000,
      currency: "USD"
    )

    # Day 2: Add transactions, trades and a valuation
    account.balances.create!(
      date: @test_period_start + 1.day,
      balance: 8500,  # Valuation sets this
      cash_balance: 1070,  # Cash increased by transactions
      currency: "USD"
    )

    # Create transactions
    create_transaction(
      account: account,
      date: @test_period_start + 1.day,
      amount: -50,
      name: "Interest payment"
    )
    create_transaction(
      account: account,
      date: @test_period_start + 1.day,
      amount: -20,
      name: "Interest payment"
    )

    # Create a trade
    create_trade(
      securities(:aapl),
      account: account,
      qty: 5,
      date: @test_period_start + 1.day,
      price: 150  # 5 * 150 = 750
    )

    # Create valuation
    create_valuation(
      account: account,
      date: @test_period_start + 1.day,
      amount: 8500
    )

    entries = account.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(account, entries)

    activities = feed_data.entries_by_date
    day2_activity = find_activity_for_date(activities, @test_period_start + 1.day)

    assert_not_nil day2_activity

    # Cash change should be $70 (50 + 20 from transactions only, not trades)
    assert_equal 70, day2_activity.cash_balance_trend.value.amount.to_i

    # Holdings change should be 750 (from the trade)
    assert_equal 750, day2_activity.holdings_value_trend.value.amount.to_i

    # Total balance change
    assert_in_delta 1178.44, day2_activity.balance_trend.value.amount.to_f, 0.01
  end

  test "normalizes multi-currency entries on valuation days" do
    # Create EUR account
    eur_account = @family.accounts.create!(name: "EUR Investment", accountable: Investment.new, currency: "EUR", balance: 0)

    # Day 1: Starting balance
    eur_account.balances.create!(
      date: @test_period_start,
      balance: 1000,
      cash_balance: 500,
      currency: "EUR"
    )

    # Day 2: Multi-currency transactions and valuation
    eur_account.balances.create!(
      date: @test_period_start + 1.day,
      balance: 2000,
      cash_balance: 600,
      currency: "EUR"
    )

    # Create USD transaction (should be converted to EUR)
    create_transaction(
      account: eur_account,
      date: @test_period_start + 1.day,
      amount: -100,
      currency: "USD",
      name: "USD Payment"
    )

    # Create exchange rate: 1 USD = 0.9 EUR
    ExchangeRate.create!(
      date: @test_period_start + 1.day,
      from_currency: "USD",
      to_currency: "EUR",
      rate: 0.9
    )

    # Create valuation
    create_valuation(
      account: eur_account,
      date: @test_period_start + 1.day,
      amount: 2000
    )

    entries = eur_account.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(eur_account, entries)

    activities = feed_data.entries_by_date
    day2_activity = find_activity_for_date(activities, @test_period_start + 1.day)

    assert_not_nil day2_activity

    # Cash change should be 90 EUR (100 USD * 0.9)
    # The transaction is -100 USD, which becomes +100 when inverted, then 100 * 0.9 = 90 EUR
    assert_equal 90, day2_activity.cash_balance_trend.value.amount.to_i
    assert_equal "EUR", day2_activity.cash_balance_trend.value.currency.iso_code
  end

  private
    def find_activity_for_date(activities, date)
      activities.find { |a| a.date == date }
    end

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

      # Create daily balances for investment account with cash_balance
      @investment.balances.create!(
        date: @test_period_start,
        balance: 500,
        cash_balance: 500,
        currency: "USD"
      )
      @investment.balances.create!(
        date: @test_period_start + 1.day,
        balance: 500,
        cash_balance: 500,
        currency: "USD"
      )
      @investment.balances.create!(
        date: @test_period_start + 2.days,
        balance: 1900,  # 1500 holdings + 400 cash
        cash_balance: 400,  # After -100 EUR transaction
        currency: "USD"
      )

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
