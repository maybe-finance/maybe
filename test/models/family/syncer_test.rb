require "test_helper"

class Family::SyncerTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
  end

  test "syncs plaid items and manual accounts" do
    family_sync = syncs(:family)

    manual_accounts_count = @family.accounts.manual.count
    items_count = @family.plaid_items.count

    syncer = Family::Syncer.new(@family)
    syncer.perform_sync(start_date: family_sync.start_date)

    assert_equal manual_accounts_count + items_count, syncer.child_syncables.count
  end
end
