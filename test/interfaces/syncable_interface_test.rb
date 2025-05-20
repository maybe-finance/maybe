require "test_helper"

module SyncableInterfaceTest
  extend ActiveSupport::Testing::Declarative
  include ActiveJob::TestHelper

  test "can sync later" do
    assert_difference "@syncable.syncs.count", 1 do
      assert_enqueued_with job: SyncJob do
        @syncable.sync_later(window_start_date: 2.days.ago.to_date)
      end
    end
  end

  test "can perform sync" do
    mock_sync = mock
    @syncable.class.any_instance.expects(:perform_sync).with(mock_sync).once
    @syncable.perform_sync(mock_sync)
  end

  test "second sync request widens existing pending window" do
    later_start = 2.days.ago.to_date
    first_sync = @syncable.sync_later(window_start_date: later_start, window_end_date: later_start)

    earlier_start = 5.days.ago.to_date
    wider_end     = Date.current

    assert_no_difference "@syncable.syncs.count" do
      @syncable.sync_later(window_start_date: earlier_start, window_end_date: wider_end)
    end

    first_sync.reload
    assert_equal earlier_start, first_sync.window_start_date
    assert_equal wider_end, first_sync.window_end_date
  end
end
