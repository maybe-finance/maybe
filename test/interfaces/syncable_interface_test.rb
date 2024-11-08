require "test_helper"

module SyncableInterfaceTest
  extend ActiveSupport::Testing::Declarative
  include ActiveJob::TestHelper

  test "can sync later" do
    assert_enqueued_with job: SyncJob, args: [ @syncable, start_date: nil ] do
      @syncable.sync_later
    end
  end

  test "can sync" do
    assert_difference "@syncable.syncs.count", 1 do
      @syncable.sync(start_date: 2.days.ago.to_date)
    end
  end

  test "needs sync if last sync is yesterday or older" do
    assert_not @syncable.needs_sync?

    @syncable.syncs.first.update! last_ran_at: 2.days.ago

    assert @syncable.needs_sync?
  end

  test "implements sync_data" do
    assert_respond_to @syncable, :sync_data
  end
end
