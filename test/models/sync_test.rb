require "test_helper"

class SyncTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "runs successful sync" do
    syncable = accounts(:depository)
    sync = Sync.create!(syncable: syncable, last_ran_at: 1.day.ago)

    syncable.expects(:perform_sync).with(sync: sync, start_date: sync.start_date).once

    assert_equal "pending", sync.status

    previously_ran_at = sync.last_ran_at

    sync.perform

    assert sync.last_ran_at > previously_ran_at
    assert_equal "completed", sync.status
  end

  test "handles sync errors" do
    syncable = accounts(:depository)
    sync = Sync.create!(syncable: syncable, last_ran_at: 1.day.ago)

    syncable.expects(:perform_sync).with(sync: sync, start_date: sync.start_date).raises(StandardError.new("test sync error"))

    assert_equal "pending", sync.status
    previously_ran_at = sync.last_ran_at

    sync.perform

    assert sync.last_ran_at > previously_ran_at
    assert_equal "failed", sync.status
    assert_equal "test sync error", sync.error
  end

  test "can run nested syncs that alert the parent when complete" do
    family = families(:dylan_family)
    plaid_item = plaid_items(:one)
    account = accounts(:connected)

    family_sync = Sync.create!(syncable: family)
    plaid_item_sync = Sync.create!(syncable: plaid_item, parent: family_sync)
    account_sync = Sync.create!(syncable: account, parent: plaid_item_sync)

    assert_equal "pending", family_sync.status
    assert_equal "pending", plaid_item_sync.status
    assert_equal "pending", account_sync.status

    family.expects(:perform_sync).with(sync: family_sync, start_date: family_sync.start_date).once

    family_sync.perform

    assert_equal "syncing", family_sync.reload.status

    plaid_item.expects(:perform_sync).with(sync: plaid_item_sync, start_date: plaid_item_sync.start_date).once

    plaid_item_sync.perform

    assert_equal "syncing", family_sync.reload.status
    assert_equal "syncing", plaid_item_sync.reload.status

    account.expects(:perform_sync).with(sync: account_sync, start_date: account_sync.start_date).once

    # Since these are accessed through `parent`, they won't necessarily be the same
    # instance we configured above
    Account.any_instance.expects(:perform_post_sync).once
    PlaidItem.any_instance.expects(:perform_post_sync).once
    Family.any_instance.expects(:perform_post_sync).once

    account_sync.perform

    assert_equal "completed", family_sync.reload.status
    assert_equal "completed", plaid_item_sync.reload.status
    assert_equal "completed", account_sync.reload.status
  end
end
