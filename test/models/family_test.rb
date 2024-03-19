require "test_helper"
require "csv"

class FamilyTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)

    @family.accounts.each do |account|
      account.sync
    end
  end

  test "should have many users" do
    assert @family.users.size > 0
    assert @family.users.include?(users(:family_admin))
  end

  test "should have many accounts" do
    assert @family.accounts.size > 0
  end

  test "should destroy dependent users" do
    assert_difference("User.count", -@family.users.count) do
      @family.destroy
    end
  end

  test "should destroy dependent accounts" do
    assert_difference("Account.count", -@family.accounts.count) do
      @family.destroy
    end
  end

  test "should destroy dependent transaction categories" do
    assert_difference("Transaction::Category.count", -@family.transaction_categories.count) do
      @family.destroy
    end
  end

  test "should calculate total assets" do
    assert_equal Money.new(25550), @family.assets_money
  end

  test "should calculate total liabilities" do
    assert_equal Money.new(1000), @family.liabilities_money
  end

  test "should calculate net worth" do
    assert_equal Money.new(24550), @family.net_worth_money
  end

  test "should calculate snapshot correctly" do
    # See this Google Sheet for calculations and expected results for dylan_family:
    # https://docs.google.com/spreadsheets/d/18LN5N-VLq4b49Mq1fNwF7_eBiHSQB46qQduRtdAEN98/edit?usp=sharing
    expected_snapshots = CSV.read("test/fixtures/family/expected_snapshots.csv", headers: true).map do |row|
      {
        "date" => (Date.current + row["date_offset"].to_i.days).to_date,
        "net_worth" => row["net_worth"],
        "assets" => row["assets"],
        "liabilities" => row["liabilities"]
      }
    end

    asset_series = @family.snapshot[:asset_series]
    liability_series = @family.snapshot[:liability_series]
    net_worth_series = @family.snapshot[:net_worth_series]

    assert_equal expected_snapshots.count, asset_series.values.count
    assert_equal expected_snapshots.count, liability_series.values.count
    assert_equal expected_snapshots.count, net_worth_series.values.count

    expected_snapshots.each_with_index do |row, index|
      expected_assets = TimeSeries::Value.new(date: row["date"], value: Money.new(row["assets"].to_d))
      expected_liabilities = TimeSeries::Value.new(date: row["date"], value: Money.new(row["liabilities"].to_d))
      expected_net_worth = TimeSeries::Value.new(date: row["date"], value: Money.new(row["net_worth"].to_d))

      assert_equal expected_assets, asset_series.values[index]
      assert_equal expected_liabilities, liability_series.values[index]
      assert_equal expected_net_worth, net_worth_series.values[index]
    end
  end

  test "should exclude disabled accounts from calculations" do
    assets_before = @family.assets
    liabilities_before = @family.liabilities
    net_worth_before = @family.net_worth

    disabled_checking = accounts(:checking)
    disabled_cc = accounts(:credit_card)

    disabled_checking.update!(is_active: false)
    disabled_cc.update!(is_active: false)

    assert_equal assets_before - disabled_checking.balance, @family.assets
    assert_equal liabilities_before - disabled_cc.balance, @family.liabilities
    assert_equal net_worth_before - disabled_checking.balance + disabled_cc.balance, @family.net_worth
  end
end
