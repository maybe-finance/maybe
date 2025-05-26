require "test_helper"

class SyncJobTest < ActiveJob::TestCase
  test "sync is performed" do
    syncable = accounts(:depository)

    sync = syncable.syncs.create!

    sync.expects(:perform).once

    SyncJob.perform_now(sync)
  end
end
