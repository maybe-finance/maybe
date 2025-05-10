require "test_helper"

class Family::SyncerTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
  end

  test "syncs plaid items and manual accounts" do
    family_sync = syncs(:family)

    manual_accounts_count = @family.accounts.manual.count
    items_count = @family.plaid_items.count

    Account.any_instance.expects(:sync_later)
      .with(start_date: nil, parent_sync: family_sync)
      .times(manual_accounts_count)

    PlaidItem.any_instance.expects(:sync_later)
      .with(start_date: nil, parent_sync: family_sync)
      .times(items_count)

    Family::Syncer.new(@family).perform_sync(family_sync, start_date: family_sync.start_date)
  end
end
