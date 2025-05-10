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

  test "can sync" do
    assert_difference "@syncable.syncs.count", 1 do
      @syncable.sync(start_date: 2.days.ago.to_date)
    end
  end
end
