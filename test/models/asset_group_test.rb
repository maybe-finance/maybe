require "test_helper"

class AssetGroupTest < ActiveSupport::TestCase
  def setup
    @accounts = [
      Account.new(balance: Money.new(100_00), accountable_type: "Depository"),
      Account.new(balance: Money.new(200_00), accountable_type: "Depository"),
      Account.new(balance: Money.new(300_00), accountable_type: "Investment")
    ]
  end

  def test_from_accounts
    asset_groups = AssetGroup.from_accounts(@accounts)

    assert_equal 2, asset_groups.length
  end

  def test_asset_group_attribute
    asset_groups = AssetGroup.from_accounts(@accounts)
    depository_group = asset_groups.find { |asset_group| asset_group.type == Accountable.from_type("Depository") }

    assert_equal Money.new(300_00), depository_group.total_asset_value
    assert_equal 50.0, depository_group.percentage_held
    assert_equal "account-depository", depository_group.param
  end
end
