require "test_helper"

module SyncableInterfaceTest
  extend ActiveSupport::Testing::Declarative
  include ActiveJob::TestHelper

  test "can sync later" do
    assert_difference "@syncable.syncs.count", 1 do
      assert_enqueued_with job: SyncJob do
        @syncable.sync_later
      end
    end
  end

  test "can perform sync" do
    mock_sync = mock
    @syncable.class.any_instance.expects(:perform_sync).with(mock_sync).once
    @syncable.perform_sync(mock_sync)
  end
end
