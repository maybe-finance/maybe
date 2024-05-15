require "test_helper"
require "csv"

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:checking)
    @family = families(:dylan_family)
    @snapshots = CSV.read("test/fixtures/family/expected_snapshots.csv", headers: true).map do |row|
      {
        "date" => (Date.current + row["date_offset"].to_i.days).to_date,
        "assets" => row["assets"],
        "liabilities" => row["liabilities"],
        "Account::Depository" => row["depositories"],
        "Account::Credit" => row["credits"],
        "Account::OtherAsset" => row["other_assets"]
      }
    end
  end

  test "new account should be valid" do
    assert @account.valid?
    assert_not_nil @account.accountable_id
    assert_not_nil @account.accountable
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

  test "syncs regular account" do
    @account.sync
    assert_equal "ok", @account.status
    assert_equal 31, @account.balances.count
  end

  test "syncs foreign currency account" do
    account = accounts(:eur_checking)
    account.sync
    assert_equal "ok", account.status
    assert_equal 31, account.balances.where(currency: "USD").count
    assert_equal 31, account.balances.where(currency: "EUR").count
  end
  test "groups accounts by type" do
    @family.accounts.each do |account|
      account.sync
    end

    result = @family.accounts.by_group(period: Period.all)

    expected_assets = @snapshots.last["assets"].to_d
    expected_liabilities = @snapshots.last["liabilities"].to_d

    assets = result[:assets]
    liabilities = result[:liabilities]

    assert_equal @family.assets, assets.sum
    assert_equal @family.liabilities, liabilities.sum

    depositories = assets.children.find { |group| group.name == "Account::Depository" }
    properties = assets.children.find { |group| group.name == "Account::Property" }
    vehicles = assets.children.find { |group| group.name == "Account::Vehicle" }
    investments = assets.children.find { |group| group.name == "Account::Investment" }
    other_assets = assets.children.find { |group| group.name == "Account::OtherAsset" }

    credits = liabilities.children.find { |group| group.name == "Account::Credit" }
    loans = liabilities.children.find { |group| group.name == "Account::Loan" }
    other_liabilities = liabilities.children.find { |group| group.name == "Account::OtherLiability" }

    assert_equal 4, depositories.children.count
    assert_equal 0, properties.children.count
    assert_equal 0, vehicles.children.count
    assert_equal 0, investments.children.count
    assert_equal 1, other_assets.children.count

    assert_equal 1, credits.children.count
    assert_equal 0, loans.children.count
    assert_equal 0, other_liabilities.children.count
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
    assert_difference("Transaction.count", -@account.transactions.count) do
      @account.destroy
    end
  end

  test "should destroy dependent balances" do
    assert_difference("Account::Balance.count", -@account.balances.count) do
      @account.destroy
    end
  end

  test "should destroy dependent valuations" do
    assert_difference("Valuation.count", -@account.valuations.count) do
      @account.destroy
    end
  end
end
