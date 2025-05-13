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
end
