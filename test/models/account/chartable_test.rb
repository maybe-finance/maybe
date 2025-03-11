require "test_helper"

class Account::ChartableTest < ActiveSupport::TestCase
  test "generates gapfilled balance series" do
    account = accounts(:depository)
    account.balances.delete_all

    account.balances.create!(date: 20.days.ago.to_date, balance: 5000, currency: "USD")
    account.balances.create!(date: 10.days.ago.to_date, balance: 5000, currency: "USD")

    period = Period.last_30_days
    series = account.balance_series(period: period)
    assert_equal period.days, series.values.count
    assert_equal 0, series.values.first.trend.current.amount
    assert_equal 5000, series.values.find { |v| v.date == 20.days.ago.to_date }.trend.current.amount
    assert_equal 5000, series.values.find { |v| v.date == 10.days.ago.to_date }.trend.current.amount
    assert_equal 5000, series.values.last.trend.current.amount
  end

  test "combines assets and liabilities for multiple accounts properly" do
    family = families(:empty)

    asset = family.accounts.create!(name: "Asset", currency: "USD", balance: 5000, accountable: Depository.new)
    liability = family.accounts.create!(name: "Liability", currency: "USD", balance: 2000, accountable: CreditCard.new)

    asset.balances.create!(date: 20.days.ago.to_date, balance: 4000, currency: "USD")
    asset.balances.create!(date: 10.days.ago.to_date, balance: 5000, currency: "USD")

    liability.balances.create!(date: 20.days.ago.to_date, balance: 1000, currency: "USD")
    liability.balances.create!(date: 10.days.ago.to_date, balance: 1500, currency: "USD")

    series = family.accounts.balance_series(currency: "USD", period: Period.last_30_days)

    assert_equal 0, series.values.first.trend.current.amount
    assert_equal 3000, series.values.find { |v| v.date == 20.days.ago.to_date }.trend.current.amount
    assert_equal 3500, series.values.last.trend.current.amount
  end

  test "generates correct totals for multi currency families" do
    family = families(:empty)
    family.update!(currency: "USD")

    usd_account = family.accounts.create!(name: "Asset", currency: "USD", balance: 5000, accountable: Depository.new)
    eur_account = family.accounts.create!(name: "Asset", currency: "EUR", balance: 1000, accountable: Depository.new)

    usd_account.balances.create!(date: 3.days.ago.to_date, balance: 5000, currency: "USD")
    eur_account.balances.create!(date: 3.days.ago.to_date, balance: 1000, currency: "EUR")

    # 1 EUR = 1.1 USD, so 1000 EUR = 1100 USD
    ExchangeRate.create!(from_currency: "EUR", to_currency: "USD", date: 3.days.ago.to_date, rate: 1.1)
    ExchangeRate.create!(from_currency: "EUR", to_currency: "USD", date: 2.days.ago.to_date, rate: 1.1)
    ExchangeRate.create!(from_currency: "EUR", to_currency: "USD", date: 1.days.ago.to_date, rate: 1.1)
    ExchangeRate.create!(from_currency: "EUR", to_currency: "USD", date: Date.current, rate: 1.1)

    series = family.accounts.balance_series(currency: "USD", period: Period.last_7_days)

    assert_equal 0, series.values.first.trend.current.amount
    assert_equal 6100, series.values.find { |v| v.date == 3.days.ago.to_date }.trend.current.amount
    assert_equal 6100, series.values.last.trend.current.amount
  end
end
