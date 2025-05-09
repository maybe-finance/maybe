require "test_helper"

class SyncTest < ActiveSupport::TestCase
  setup do
    @sync = syncs(:account)
    @sync.update(status: "pending")
  end

  test "runs successful sync" do
    @sync.syncable.expects(:sync_data).with(@sync, start_date: @sync.start_date).once

    assert_equal "pending", @sync.status

    previously_ran_at = @sync.last_ran_at

    @sync.perform

    assert @sync.last_ran_at > previously_ran_at
    assert_equal "completed", @sync.status
  end

  test "handles sync errors" do
    @sync.syncable.expects(:sync_data).with(@sync, start_date: @sync.start_date).raises(StandardError.new("test sync error"))

    assert_equal "pending", @sync.status
    previously_ran_at = @sync.last_ran_at

    @sync.perform

    assert @sync.last_ran_at > previously_ran_at
    assert_equal "failed", @sync.status
    assert_equal "test sync error", @sync.error
  end

  # Order is important here.  Parent syncs must implement sync_data so that their own work
  # is 100% complete *prior* to queueing up child syncs.
  test "runs sync with child syncs" do
    family = families(:dylan_family)

    parent = Sync.create!(syncable: family)
    child1 = Sync.create!(syncable: family.accounts.first, parent: parent)
    child2 = Sync.create!(syncable: family.accounts.second, parent: parent)
    grandchild = Sync.create!(syncable: family.accounts.last, parent: child2)

    parent.syncable.expects(:sync_data).returns([]).once
    child1.syncable.expects(:sync_data).returns([]).once
    child2.syncable.expects(:sync_data).returns([]).once
    grandchild.syncable.expects(:sync_data).returns([]).once

    assert_equal "pending", parent.status
    assert_equal "pending", child1.status
    assert_equal "pending", child2.status
    assert_equal "pending", grandchild.status

    parent.perform
    assert_equal "syncing", parent.reload.status

    child1.perform
    assert_equal "completed", child1.reload.status
    assert_equal "syncing", parent.reload.status

    child2.perform
    assert_equal "syncing", child2.reload.status
    assert_equal "completed", child1.reload.status
    assert_equal "syncing", parent.reload.status

    # Will complete the parent and grandparent syncs
    grandchild.perform
    assert_equal "completed", grandchild.reload.status
    assert_equal "completed", child1.reload.status
    assert_equal "completed", child2.reload.status
    assert_equal "completed", parent.reload.status
  end
end
