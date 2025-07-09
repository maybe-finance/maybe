require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  include SyncableInterfaceTest

  def setup
    @syncable = @family = families(:dylan_family)
  end

  test "creates manual property account" do
    account = @family.create_property_account!(
      name: "My House",
      current_value: 450000,
      purchase_price: 400000,
      purchase_date: 1.year.ago.to_date
    )

    valuations = account.valuations
    assert_equal 1, valuations.count
    assert_equal "opening_anchor", valuations.first.kind
    assert_equal 400000, valuations.first.balance
    assert_equal 0, valuations.first.cash_balance

    assert_equal "My House", account.name
    assert_equal 450000, account.balance
    assert_equal 0, account.cash_balance
  end

  test "creates manual vehicle account" do
    # TODO
  end

  test "creates manual depository account" do
    # TODO
  end

  test "creates manual investment account" do
    # TODO
  end

  test "creates manual other asset or liability account" do
    # TODO
  end

  test "creates manual crypto account" do
    # TODO
  end

  test "creates manual credit card account" do
    # TODO
  end

  test "creates manual loan account" do
    # TODO
  end

  test "creates linked depository account" do
    # TODO
  end

  test "creates linked investment account" do
    # TODO
  end

  test "creates linked credit card account" do
    # TODO
  end

  test "creates linked loan account" do
    # TODO
  end
end
