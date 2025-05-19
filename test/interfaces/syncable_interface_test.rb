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

  test "any prior syncs for the same syncable entity are marked stale when new sync is requested" do
    stale_sync = @syncable.sync_later
    new_sync = @syncable.sync_later

    assert_equal "stale", stale_sync.reload.status
    assert_equal "pending", new_sync.reload.status
  end
end
