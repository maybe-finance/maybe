require "test_helper"

class SyncTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "runs successful sync" do
    sync = Sync.create!(syncable: accounts(:depository), last_ran_at: 1.day.ago)

    Account::Syncer.any_instance.expects(:perform_sync).with(start_date: sync.start_date).once

    assert_equal "pending", sync.status

    previously_ran_at = sync.last_ran_at

    sync.perform

    assert sync.last_ran_at > previously_ran_at
    assert_equal "completed", sync.status
  end

  test "handles sync errors" do
    sync = Sync.create!(syncable: accounts(:depository), last_ran_at: 1.day.ago)
    Account::Syncer.any_instance.expects(:perform_sync).with(start_date: sync.start_date).raises(StandardError.new("test sync error"))

    assert_equal "pending", sync.status
    previously_ran_at = sync.last_ran_at

    sync.perform

    assert sync.last_ran_at > previously_ran_at
    assert_equal "failed", sync.status
    assert_equal "test sync error", sync.error
  end

  test "can run nested syncs that alert the parent when complete" do
    # Clear out fixture syncs
    Sync.destroy_all

    # These fixtures represent a Parent -> Child -> Grandchild sync hierarchy
    # Family -> PlaidItem -> Account
    family = families(:dylan_family)
    plaid_item = plaid_items(:one)
    account = accounts(:connected)

    sync = Sync.create!(syncable: family)

    Family::Syncer.any_instance.expects(:perform_sync).with(start_date: sync.start_date).once
    Family::Syncer.any_instance.expects(:perform_post_sync).once
    Family::Syncer.any_instance.expects(:child_syncables).returns([ plaid_item ])

    PlaidItem::Syncer.any_instance.expects(:perform_sync).with(start_date: sync.start_date).once
    PlaidItem::Syncer.any_instance.expects(:perform_post_sync).once
    PlaidItem::Syncer.any_instance.expects(:child_syncables).returns([ account ])

    Account::Syncer.any_instance.expects(:perform_sync).with(start_date: sync.start_date).once
    Account::Syncer.any_instance.expects(:perform_post_sync).once
    Account::Syncer.any_instance.expects(:child_syncables).returns([])

    sync.perform

    assert_equal 1, family.syncs.count
    assert_equal "syncing", family.syncs.first.status
    assert_equal 1, plaid_item.syncs.count
    assert_equal "pending", plaid_item.syncs.first.status

    # We have to perform jobs 2x because the child sync will schedule the grandchild sync,
    # which then needs to be run.
    perform_enqueued_jobs

    assert_equal 1, family.syncs.count
    assert_equal "syncing", family.syncs.first.status
    assert_equal 1, plaid_item.syncs.count
    assert_equal "syncing", plaid_item.syncs.first.status
    assert_equal 1, account.syncs.count
    assert_equal "pending", account.syncs.first.status

    perform_enqueued_jobs

    assert_equal 1, family.syncs.count
    assert_equal "completed", family.syncs.first.status
    assert_equal 1, plaid_item.syncs.count
    assert_equal "completed", plaid_item.syncs.first.status
    assert_equal 1, account.syncs.count
    assert_equal "completed", account.syncs.first.status
  end
end
