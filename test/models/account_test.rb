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

  test "groups accounts by type" do
    @family.accounts.each do |account|
      account.sync
    end

    result = @family.accounts.by_group({ period: Period.all, currency: @family.currency })

    expected_assets = @snapshots.last["assets"].to_d
    expected_liabilities = @snapshots.last["liabilities"].to_d

    assets = result[:asset][:total]
    liabilities = result[:liability][:total]

    assert_equal expected_assets, assets
    assert_equal expected_liabilities, liabilities

    assert_equal [ "Account::OtherAsset", "Account::Depository"  ], result[:asset][:groups].keys
    assert_equal [ "Account::Credit" ], result[:liability][:groups].keys

    assert_equal @snapshots.last["Account::Depository"].to_d, result[:asset][:groups]["Account::Depository"][:end_balance]
    assert_equal @snapshots.last["Account::Credit"].to_d, result[:liability][:groups]["Account::Credit"][:end_balance]
    assert_equal @snapshots.last["Account::OtherAsset"].to_d, result[:asset][:groups]["Account::OtherAsset"][:end_balance]

    assert_equal @snapshots.first["Account::Depository"].to_d, result[:asset][:groups]["Account::Depository"][:start_balance]
    assert_equal @snapshots.first["Account::Credit"].to_d, result[:liability][:groups]["Account::Credit"][:start_balance]
    assert_equal @snapshots.first["Account::OtherAsset"].to_d, result[:asset][:groups]["Account::OtherAsset"][:start_balance]

    assert_equal 4, result[:asset][:groups]["Account::Depository"][:accounts].count
    assert_equal 1, result[:asset][:groups]["Account::OtherAsset"][:accounts].count
    assert_equal 1, result[:liability][:groups]["Account::Credit"][:accounts].count

    expected_depository_allocation = @snapshots.last["Account::Depository"].to_d / expected_assets * 100
    expected_credit_allocation = @snapshots.last["Account::Credit"].to_d / expected_liabilities * 100
    expected_other_asset_allocation = @snapshots.last["Account::OtherAsset"].to_d / expected_assets * 100

    assert_equal expected_depository_allocation.round(2), result[:asset][:groups]["Account::Depository"][:allocation]
    assert_equal expected_credit_allocation.round(2), result[:liability][:groups]["Account::Credit"][:allocation]
    assert_equal expected_other_asset_allocation.round(2), result[:asset][:groups]["Account::OtherAsset"][:allocation]
  end

  test "groups accounts by type with period" do
    @family.accounts.each do |account|
      account.sync
    end

    START_OFFSET = 7
    END_OFFSET = 2

    result = @family.accounts.by_group({ period: Period.new(date_range: START_OFFSET.days.ago.to_date..END_OFFSET.days.ago.to_date), currency: @family.currency })

    expected_start_depository = @snapshots[-START_OFFSET-1]["Account::Depository"].to_d
    expected_end_depository = @snapshots[-END_OFFSET-1]["Account::Depository"].to_d

    assert_equal expected_start_depository, result[:asset][:groups]["Account::Depository"][:start_balance]
    assert_equal expected_end_depository, result[:asset][:groups]["Account::Depository"][:end_balance]

    expected_start_credit = @snapshots[-START_OFFSET-1]["Account::Credit"].to_d
    expected_end_credit = @snapshots[-END_OFFSET-1]["Account::Credit"].to_d

    assert_equal expected_start_credit, result[:liability][:groups]["Account::Credit"][:start_balance]
    assert_equal expected_end_credit, result[:liability][:groups]["Account::Credit"][:end_balance]

    expected_start_other_asset = @snapshots[-START_OFFSET-1]["Account::OtherAsset"].to_d
    expected_end_other_asset = @snapshots[-END_OFFSET-1]["Account::OtherAsset"].to_d

    assert_equal expected_start_other_asset, result[:asset][:groups]["Account::OtherAsset"][:start_balance]
    assert_equal expected_end_other_asset, result[:asset][:groups]["Account::OtherAsset"][:end_balance]
  end
end
