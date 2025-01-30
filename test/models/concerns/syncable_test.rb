require "test_helper"

class SyncableTest < ActiveSupport::TestCase
  setup do
    @syncable = syncs(:account).syncable
  end

  test "sync_error returns nil when no syncs exist" do
    @syncable.syncs.destroy_all
    assert_nil @syncable.sync_error
  end

  test "sync_error returns the error message from the latest sync" do
    error_message = "Test error message"
    sync = @syncable.syncs.create!(status: :failed, error: error_message)
    assert_equal error_message, @syncable.sync_error
  end

  test "sync_error returns nil when latest sync has no error" do
    @syncable.syncs.destroy_all
    sync = @syncable.syncs.create!(status: :completed)
    assert_nil @syncable.sync_error
  end

  test "sync_error returns latest sync error when multiple syncs exist" do
    @syncable.syncs.destroy_all
    @syncable.syncs.create!(status: :failed, error: "Old error")
    latest_sync = @syncable.syncs.create!(status: :failed, error: "Latest error")
    assert_equal "Latest error", @syncable.sync_error
  end
end
