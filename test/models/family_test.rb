require "test_helper"
require "csv"

class FamilyTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper
  include SyncableInterfaceTest

  def setup
    @family = families(:empty)
    @syncable = families(:dylan_family)
  end

  test "syncs plaid items and manual accounts" do
    family_sync = syncs(:family)

    manual_accounts_count = @syncable.accounts.manual.count
    items_count = @syncable.plaid_items.count

    Account.any_instance.expects(:sync_later)
      .with(start_date: nil)
      .times(manual_accounts_count)

    PlaidItem.any_instance.expects(:sync_later)
      .with(start_date: nil)
      .times(items_count)

    @syncable.sync_data(start_date: family_sync.start_date)
  end

  test "calculates assets" do
    assert_equal Money.new(0, @family.currency), @family.assets

    create_account(balance: 1000, accountable: Depository.new)
    create_account(balance: 5000, accountable: OtherAsset.new)
    create_account(balance: 10000, accountable: CreditCard.new) # ignored

    assert_equal Money.new(1000 + 5000, @family.currency), @family.assets
  end

  test "calculates liabilities" do
    assert_equal Money.new(0, @family.currency), @family.liabilities

    create_account(balance: 1000, accountable: CreditCard.new)
    create_account(balance: 5000, accountable: OtherLiability.new)
    create_account(balance: 10000, accountable: Depository.new) # ignored

    assert_equal Money.new(1000 + 5000, @family.currency), @family.liabilities
  end

  test "calculates net worth" do
    assert_equal Money.new(0, @family.currency), @family.net_worth

    create_account(balance: 1000, accountable: CreditCard.new)
    create_account(balance: 50000, accountable: Depository.new)

    assert_equal Money.new(50000 - 1000, @family.currency), @family.net_worth
  end

  test "should exclude disabled accounts from calculations" do
    cc = create_account(balance: 1000, accountable: CreditCard.new)
    create_account(balance: 50000, accountable: Depository.new)

    assert_equal Money.new(50000 - 1000, @family.currency), @family.net_worth

    cc.update! is_active: false

    assert_equal Money.new(50000, @family.currency), @family.net_worth
  end

  private
    def create_account(attributes = {})
      account = @family.accounts.create! name: "Test", currency: "USD", **attributes
      account
    end
end
