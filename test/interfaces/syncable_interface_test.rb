require "test_helper"

module SyncableInterfaceTest
  extend ActiveSupport::Testing::Declarative
  include ActiveJob::TestHelper

  test "can sync later" do
    assert_difference "@syncable.syncs.count", 1 do
      assert_enqueued_with job: SyncJob do
        @syncable.sync_later(start_date: 2.days.ago.to_date)
      end
    end
  end

  test "can perform sync" do
    mock_sync = mock
    @syncable.class.any_instance.expects(:perform_sync).with(sync: mock_sync, start_date: 2.days.ago.to_date).once
    @syncable.perform_sync(sync: mock_sync, start_date: 2.days.ago.to_date)
  end
end
