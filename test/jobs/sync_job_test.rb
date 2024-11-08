require "test_helper"

class SyncJobTest < ActiveJob::TestCase
  test "sync is performed" do
    syncable = accounts(:depository)
    syncable.expects(:sync).once

    SyncJob.perform_now(syncable)
  end
end
