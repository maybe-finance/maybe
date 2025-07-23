require "test_helper"

class Balance::ChartSeriesBuilderTest < ActiveSupport::TestCase
  include BalanceTestHelper

  setup do
  end

  test "balance series with fallbacks and gapfills" do
    account = accounts(:depository)
    account.balances.destroy_all

    # With gaps
    create_balance(account: account, date: 3.days.ago.to_date, balance: 1000)
    create_balance(account: account, date: 1.day.ago.to_date, balance: 1100)
    create_balance(account: account, date: Date.current, balance: 1200)

    builder = Balance::ChartSeriesBuilder.new(
      account_ids: [ account.id ],
      currency: "USD",
      period: Period.last_30_days,
      interval: "1 day"
    )

    assert_equal 31, builder.balance_series.size # Last 30 days == 31 total balances
    assert_equal 0, builder.balance_series.first.value

    expected = [
      0, # No value, so fallback to 0
      1000,
      1000, # Last observation carried forward
      1100,
      1200
    ]

    assert_equal expected, builder.balance_series.last(5).map { |v| v.value.amount }
  end

  test "exchange rates apply locf when missing" do
    account = accounts(:depository)
    account.balances.destroy_all

    create_balance(account: account, date: 2.days.ago.to_date, balance: 1000)
    create_balance(account: account, date: 1.day.ago.to_date, balance: 1100)
    create_balance(account: account, date: Date.current, balance: 1200)

    builder = Balance::ChartSeriesBuilder.new(
      account_ids: [ account.id ],
      currency: "EUR", # Will need to convert existing balances to EUR
      period: Period.custom(start_date: 2.days.ago.to_date, end_date: Date.current),
      interval: "1 day"
    )

    # Only 1 rate in DB. We'll be missing the first and last days in the series.
    # This rate should be applied to 1 day ago and today, but not 2 days ago (will fall back to 1)
    ExchangeRate.create!(date: 1.day.ago.to_date, from_currency: "USD", to_currency: "EUR", rate: 2)

    expected = [
      1000, # No rate available, so fall back to 1:1 conversion (1000 USD = 1000 EUR)
      2200, # Rate available, so use 2:1 conversion (1100 USD = 2200 EUR)
      2400 # Rate NOT available, but LOCF will use the last available rate, so use 2:1 conversion (1200 USD = 2400 EUR)
    ]

    assert_equal expected, builder.balance_series.map { |v| v.value.amount }
  end

  test "combines asset and liability accounts properly" do
    asset_account = accounts(:depository)
    liability_account = accounts(:credit_card)

    Balance.destroy_all

    create_balance(account: asset_account, date: 3.days.ago.to_date, balance: 500)
    create_balance(account: asset_account, date: 1.day.ago.to_date, balance: 1000)
    create_balance(account: asset_account, date: Date.current, balance: 1000)

    create_balance(account: liability_account, date: 3.days.ago.to_date, balance: 200)
    create_balance(account: liability_account, date: 2.days.ago.to_date, balance: 200)
    create_balance(account: liability_account, date: Date.current, balance: 100)

    builder = Balance::ChartSeriesBuilder.new(
      account_ids: [ asset_account.id, liability_account.id ],
      currency: "USD",
      period: Period.custom(start_date: 4.days.ago.to_date, end_date: Date.current),
      interval: "1 day"
    )

    expected = [
      0, # No asset or liability balances - 4 days ago
      300, # 500 - 200 = 300 - 3 days ago
      300, # 500 - 200 = 300 (500 is locf) - 2 days ago
      800, # 1000 - 200 = 800 (200 is locf) - 1 day ago
      900 # 1000 - 100 = 900 - today
    ]

    assert_equal expected, builder.balance_series.map { |v| v.value.amount }
  end

  test "when favorable direction is down balance signage inverts" do
    account = accounts(:credit_card)
    account.balances.destroy_all

    create_balance(account: account, date: 1.day.ago.to_date, balance: 1000)
    create_balance(account: account, date: Date.current, balance: 500)

    builder = Balance::ChartSeriesBuilder.new(
      account_ids: [ account.id ],
      currency: "USD",
      period: Period.custom(start_date: 1.day.ago.to_date, end_date: Date.current),
      favorable_direction: "up"
    )

    # Since favorable direction is up and balances are liabilities, the values should be negative
    expected = [ -1000, -500 ]

    assert_equal expected, builder.balance_series.map { |v| v.value.amount }

    builder = Balance::ChartSeriesBuilder.new(
      account_ids: [ account.id ],
      currency: "USD",
      period: Period.custom(start_date: 1.day.ago.to_date, end_date: Date.current),
      favorable_direction: "down"
    )

    # Since favorable direction is down and balances are liabilities, the values should be positive
    expected = [ 1000, 500 ]

    assert_equal expected, builder.balance_series.map { |v| v.value.amount }
  end
end
