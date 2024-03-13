require "test_helper"
require "csv"

class FamilyTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)

    @family.accounts.each do |account|
      account.sync
    end

    # See this Google Sheet for calculations and expected results for dylan_family:
    # https://docs.google.com/spreadsheets/d/18LN5N-VLq4b49Mq1fNwF7_eBiHSQB46qQduRtdAEN98/edit?usp=sharing
    @expected_snapshots = CSV.read("test/fixtures/family/expected_snapshots.csv", headers: true).map do |row|
      {
        "date" => (Date.current + row["date_offset"].to_i.days).to_date,
        "net_worth" => row["net_worth"],
        "assets" => row["assets"],
        "liabilities" => row["liabilities"]
      }
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
    assert_equal @expected_snapshots.last["assets"].to_d, @family.assets
  end

  test "should calculate total liabilities" do
    assert_equal @expected_snapshots.last["liabilities"].to_d, @family.liabilities
  end

  test "should calculate net worth" do
    assert_equal @expected_snapshots.last["net_worth"].to_d, @family.net_worth
  end

  test "should calculate snapshot correctly" do
    asset_series = @family.snapshot[:asset_series]
    liability_series = @family.snapshot[:liability_series]
    net_worth_series = @family.snapshot[:net_worth_series]

    assert_equal @expected_snapshots.count, asset_series.data.count
    assert_equal @expected_snapshots.count, liability_series.data.count
    assert_equal @expected_snapshots.count, net_worth_series.data.count

    @expected_snapshots.each_with_index do |row, index|
      expected = {
        date: row["date"],
        assets: row["assets"].to_d.round(2),
        liabilities: row["liabilities"].to_d.round(2),
        net_worth: row["net_worth"].to_d.round(2)
      }

      actual = {
        date: asset_series.data[index][:date],
        assets: asset_series.data[index][:value].amount.round(2),
        liabilities: liability_series.data[index][:value].amount.round(2),
        net_worth: net_worth_series.data[index][:value].amount.round(2)
      }

      assert_equal expected, actual
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
