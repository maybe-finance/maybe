require "test_helper"

class SyncTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "runs successful sync" do
    syncable = accounts(:depository)
    sync = Sync.create!(syncable: syncable)

    syncable.expects(:perform_sync).with(sync).once

    assert_equal "pending", sync.status

    sync.perform

    assert sync.completed_at < Time.now
    assert_equal "completed", sync.status
  end

  test "handles sync errors" do
    syncable = accounts(:depository)
    sync = Sync.create!(syncable: syncable)

    syncable.expects(:perform_sync).with(sync).raises(StandardError.new("test sync error"))

    assert_equal "pending", sync.status

    sync.perform

    assert sync.failed_at < Time.now
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

    family.expects(:perform_sync).with(family_sync).once

    family_sync.perform

    assert_equal "syncing", family_sync.reload.status

    plaid_item.expects(:perform_sync).with(plaid_item_sync).once

    plaid_item_sync.perform

    assert_equal "syncing", family_sync.reload.status
    assert_equal "syncing", plaid_item_sync.reload.status

    account.expects(:perform_sync).with(account_sync).once

    # Since these are accessed through `parent`, they won't necessarily be the same
    # instance we configured above
    Account.any_instance.expects(:perform_post_sync).once
    Account.any_instance.expects(:broadcast_sync_complete).once
    PlaidItem.any_instance.expects(:perform_post_sync).once
    PlaidItem.any_instance.expects(:broadcast_sync_complete).once
    Family.any_instance.expects(:perform_post_sync).once
    Family.any_instance.expects(:broadcast_sync_complete).once

    account_sync.perform

    assert_equal "completed", plaid_item_sync.reload.status
    assert_equal "completed", account_sync.reload.status
    assert_equal "completed", family_sync.reload.status
  end

  test "failures propagate up the chain" do
    family = families(:dylan_family)
    plaid_item = plaid_items(:one)
    account = accounts(:connected)

    family_sync = Sync.create!(syncable: family)
    plaid_item_sync = Sync.create!(syncable: plaid_item, parent: family_sync)
    account_sync = Sync.create!(syncable: account, parent: plaid_item_sync)

    assert_equal "pending", family_sync.status
    assert_equal "pending", plaid_item_sync.status
    assert_equal "pending", account_sync.status

    family.expects(:perform_sync).with(family_sync).once

    family_sync.perform

    assert_equal "syncing", family_sync.reload.status

    plaid_item.expects(:perform_sync).with(plaid_item_sync).once

    plaid_item_sync.perform

    assert_equal "syncing", family_sync.reload.status
    assert_equal "syncing", plaid_item_sync.reload.status

    # This error should "bubble up" to the PlaidItem and Family sync results
    account.expects(:perform_sync).with(account_sync).raises(StandardError.new("test account sync error"))

    # Since these are accessed through `parent`, they won't necessarily be the same
    # instance we configured above
    Account.any_instance.expects(:perform_post_sync).once
    PlaidItem.any_instance.expects(:perform_post_sync).once
    Family.any_instance.expects(:perform_post_sync).once

    Account.any_instance.expects(:broadcast_sync_complete).once
    PlaidItem.any_instance.expects(:broadcast_sync_complete).once
    Family.any_instance.expects(:broadcast_sync_complete).once

    account_sync.perform

    assert_equal "failed", plaid_item_sync.reload.status
    assert_equal "failed", account_sync.reload.status
    assert_equal "failed", family_sync.reload.status
  end

  test "parent failure should not change status if child succeeds" do
    family = families(:dylan_family)
    plaid_item = plaid_items(:one)
    account = accounts(:connected)

    family_sync = Sync.create!(syncable: family)
    plaid_item_sync = Sync.create!(syncable: plaid_item, parent: family_sync)
    account_sync = Sync.create!(syncable: account, parent: plaid_item_sync)

    assert_equal "pending", family_sync.status
    assert_equal "pending", plaid_item_sync.status
    assert_equal "pending", account_sync.status

    family.expects(:perform_sync).with(family_sync).raises(StandardError.new("test family sync error"))

    family_sync.perform

    assert_equal "failed", family_sync.reload.status

    plaid_item.expects(:perform_sync).with(plaid_item_sync).raises(StandardError.new("test plaid item sync error"))

    plaid_item_sync.perform

    assert_equal "failed", family_sync.reload.status
    assert_equal "failed", plaid_item_sync.reload.status

    # Leaf level sync succeeds, but shouldn't change the status of the already-failed parent syncs
    account.expects(:perform_sync).with(account_sync).once

    # Since these are accessed through `parent`, they won't necessarily be the same
    # instance we configured above
    Account.any_instance.expects(:perform_post_sync).once
    PlaidItem.any_instance.expects(:perform_post_sync).once
    Family.any_instance.expects(:perform_post_sync).once

    Account.any_instance.expects(:broadcast_sync_complete).once
    PlaidItem.any_instance.expects(:broadcast_sync_complete).once
    Family.any_instance.expects(:broadcast_sync_complete).once

    account_sync.perform

    assert_equal "failed", plaid_item_sync.reload.status
    assert_equal "failed", family_sync.reload.status
    assert_equal "completed", account_sync.reload.status
  end
end
