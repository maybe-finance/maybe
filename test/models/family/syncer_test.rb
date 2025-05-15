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

    Account.any_instance
           .expects(:sync_later)
           .with(parent_sync: family_sync, window_start_date: nil, window_end_date: nil)
           .times(manual_accounts_count)

    PlaidItem.any_instance
             .expects(:sync_later)
             .with(parent_sync: family_sync, window_start_date: nil, window_end_date: nil)
             .times(items_count)

    syncer.perform_sync(family_sync)

    assert_equal "completed", family_sync.reload.status
  end
end
