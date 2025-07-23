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

  test "returns balance for date with complete balance history" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date
    day2_activity = find_activity_for_date(activities, @test_period_start + 1.day)

    assert_not_nil day2_activity
    assert_not_nil day2_activity.balance
    assert_equal 1100, day2_activity.balance.end_balance  # End of day 2
  end

  test "returns balance for first day" do
    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date
    day1_activity = find_activity_for_date(activities, @test_period_start)

    assert_not_nil day1_activity
    assert_not_nil day1_activity.balance
    assert_equal 1000, day1_activity.balance.end_balance  # End of first day
  end

  test "returns nil balance when no balance exists for date" do
    @checking.balances.destroy_all

    entries = @checking.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@checking, entries)

    activities = feed_data.entries_by_date
    day1_activity = find_activity_for_date(activities, @test_period_start)

    assert_not_nil day1_activity
    assert_nil day1_activity.balance
  end

  test "returns cash and holdings data for investment accounts" do
    entries = @investment.entries.includes(:entryable).to_a
    feed_data = Account::ActivityFeedData.new(@investment, entries)

    activities = feed_data.entries_by_date
    day3_activity = find_activity_for_date(activities, @test_period_start + 2.days)

    assert_not_nil day3_activity
    assert_not_nil day3_activity.balance

    # Balance should have the new schema fields
    assert_equal 400, day3_activity.balance.end_cash_balance  # End of day 3 cash balance
    assert_equal 1500, day3_activity.balance.end_non_cash_balance  # Holdings value
    assert_equal 1900, day3_activity.balance.end_balance  # Total balance
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
      assert_respond_to activity, :balance
      assert_respond_to activity, :transfers
    end
  end

  test "handles valuations correctly with new balance schema" do
    # Create account with known balances
    account = @family.accounts.create!(name: "Test Investment", accountable: Investment.new, currency: "USD", balance: 0)

    # Day 1: Starting balance
    account.balances.create!(
      date: @test_period_start,
      balance: 7321.56,  # Keep old field for now
      cash_balance: 1000,  # Keep old field for now
      start_cash_balance: 0,
      start_non_cash_balance: 0,
      cash_inflows: 1000,
      cash_outflows: 0,
      non_cash_inflows: 6321.56,
      non_cash_outflows: 0,
      net_market_flows: 0,
      cash_adjustments: 0,
      non_cash_adjustments: 0,
      currency: "USD"
    )

    # Day 2: Add transactions, trades and a valuation
    account.balances.create!(
      date: @test_period_start + 1.day,
      balance: 8500,  # Keep old field for now
      cash_balance: 1070,  # Keep old field for now
      start_cash_balance: 1000,
      start_non_cash_balance: 6321.56,
      cash_inflows: 70,
      cash_outflows: 0,
      non_cash_inflows: 750,
      non_cash_outflows: 0,
      net_market_flows: 0,
      cash_adjustments: 0,
      non_cash_adjustments: 358.44,
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
    assert_not_nil day2_activity.balance

    # Check new balance fields
    assert_equal 1070, day2_activity.balance.end_cash_balance
    assert_equal 7430, day2_activity.balance.end_non_cash_balance
    assert_equal 8500, day2_activity.balance.end_balance
  end

  private
    def find_activity_for_date(activities, date)
      activities.find { |a| a.date == date }
    end

    def setup_test_data
      # Create daily balances for checking account with new schema
      5.times do |i|
        date = @test_period_start + i.days
        prev_balance = i > 0 ? 1000 + ((i - 1) * 100) : 0

        @checking.balances.create!(
          date: date,
          balance: 1000 + (i * 100),  # Keep old field for now
          cash_balance: 1000 + (i * 100),  # Keep old field for now
          start_balance: prev_balance,
          start_cash_balance: prev_balance,
          start_non_cash_balance: 0,
          cash_inflows: i == 0 ? 1000 : 100,
          cash_outflows: 0,
          non_cash_inflows: 0,
          non_cash_outflows: 0,
          net_market_flows: 0,
          cash_adjustments: 0,
          non_cash_adjustments: 0,
          currency: "USD"
        )
      end

      # Create daily balances for investment account with cash_balance
      @investment.balances.create!(
        date: @test_period_start,
        balance: 500,  # Keep old field for now
        cash_balance: 500,  # Keep old field for now
        start_balance: 0,
        start_cash_balance: 0,
        start_non_cash_balance: 0,
        cash_inflows: 500,
        cash_outflows: 0,
        non_cash_inflows: 0,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
        currency: "USD"
      )
      @investment.balances.create!(
        date: @test_period_start + 1.day,
        balance: 500,  # Keep old field for now
        cash_balance: 500,  # Keep old field for now
        start_balance: 500,
        start_cash_balance: 500,
        start_non_cash_balance: 0,
        cash_inflows: 0,
        cash_outflows: 0,
        non_cash_inflows: 0,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
        currency: "USD"
      )
      @investment.balances.create!(
        date: @test_period_start + 2.days,
        balance: 1900,  # Keep old field for now
        cash_balance: 400,  # Keep old field for now
        start_balance: 500,
        start_cash_balance: 500,
        start_non_cash_balance: 0,
        cash_inflows: 0,
        cash_outflows: 100,
        non_cash_inflows: 1500,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
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
