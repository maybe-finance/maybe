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
end
