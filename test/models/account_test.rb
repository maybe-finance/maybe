require "test_helper"
require "csv"

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:checking)
    @family = families(:dylan_family)
  end

  test "calculates required exchange rates for foreign currency account" do
    account = accounts(:eur_checking)

    expected = (31.days.ago.to_date..Date.current).map do |date|
      { date:, from: "EUR", to: "USD" }
    end

    assert_equal expected, account.required_exchange_rates.sort_by { |r| r[:date] }
  end

  test "calculates required exchange rates for multi-currency account" do
    account = accounts(:multi_currency)

    expected = [
      { date: 19.days.ago.to_date, from: "EUR", to: "USD" },
      { date: 4.days.ago.to_date, from: "EUR", to: "USD" }
    ]

    assert_equal expected, account.required_exchange_rates.sort_by { |r| r[:date] }
  end

  test "returns empty array if account does not require exchange rates" do
    assert_equal [], @account.required_exchange_rates
  end

  test "calculated required securities prices for investment accounts" do
    account = accounts(:brokerage)

    assert_equal 31.days.ago.to_date, account.effective_start_date

    expected = {
      start_date: account.effective_start_date,
      isin_codes: [ securities(:aapl).isin, securities(:toyota).isin, securities(:microsoft).isin ]
    }

    assert_equal expected, account.required_securities_prices
  end

  test "returns empty array if account does not require securities prices" do
    assert_equal [], @account.required_securities_prices
  end

  test "provides required securities prices" do
    assert_equal [], @account.required_securities_prices
  end

  test "recognizes foreign currency account" do
    regular_account = accounts(:checking)
    foreign_account = accounts(:eur_checking)
    assert_not regular_account.foreign_currency?
    assert foreign_account.foreign_currency?
  end

  test "recognizes multi currency account" do
    regular_account = accounts(:checking)
    multi_currency_account = accounts(:multi_currency)
    assert_not regular_account.multi_currency?
    assert multi_currency_account.multi_currency?
  end

  test "multi currency and foreign currency are different concepts" do
    multi_currency_account = accounts(:multi_currency)
    assert_equal multi_currency_account.family.currency, multi_currency_account.currency
    assert multi_currency_account.multi_currency?
    assert_not multi_currency_account.foreign_currency?
  end

  test "groups accounts by type" do
    @family.accounts.each do |account|
      account.sync
    end

    result = @family.accounts.by_group(period: Period.all)
    assets = result[:assets]
    liabilities = result[:liabilities]

    assert_equal @family.assets, assets.sum
    assert_equal @family.liabilities, liabilities.sum

    depositories = assets.children.find { |group| group.name == "Depository" }
    properties = assets.children.find { |group| group.name == "Property" }
    vehicles = assets.children.find { |group| group.name == "Vehicle" }
    investments = assets.children.find { |group| group.name == "Investment" }
    other_assets = assets.children.find { |group| group.name == "OtherAsset" }

    credits = liabilities.children.find { |group| group.name == "CreditCard" }
    loans = liabilities.children.find { |group| group.name == "Loan" }
    other_liabilities = liabilities.children.find { |group| group.name == "OtherLiability" }

    assert_equal 4, depositories.children.count
    assert_equal 1, properties.children.count
    assert_equal 1, vehicles.children.count
    assert_equal 1, investments.children.count
    assert_equal 1, other_assets.children.count

    assert_equal 1, credits.children.count
    assert_equal 1, loans.children.count
    assert_equal 1, other_liabilities.children.count
  end

  test "generates series with last balance equal to current account balance" do
    # If account hasn't been synced, series falls back to a single point with the current balance
    assert_equal @account.balance_money, @account.series.last.value

    @account.sync

    # Synced series will always have final balance equal to the current account balance
    assert_equal @account.balance_money, @account.series.last.value
  end

  test "generates empty series for foreign currency if no exchange rate" do
    account = accounts(:eur_checking)

    # We know EUR -> NZD exchange rate is not available in fixtures
    assert_equal 0, account.series(currency: "NZD").values.count
  end

  test "should destroy dependent transactions" do
    assert_difference("Account::Transaction.count", -@account.transactions.count) do
      @account.destroy
    end
  end

  test "should destroy dependent balances" do
    assert_difference("Account::Balance.count", -@account.balances.count) do
      @account.destroy
    end
  end

  test "should destroy dependent valuations" do
    assert_difference("Account::Valuation.count", -@account.valuations.count) do
      @account.destroy
    end
  end
end
