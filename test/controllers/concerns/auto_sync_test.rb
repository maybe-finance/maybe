require "test_helper"

class AutoSyncTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @family = @user.family

    # Start fresh
    Sync.destroy_all
  end

  test "auto-syncs family if hasn't synced" do
    assert_difference "Sync.count", 1 do
      get root_path
    end
  end

  test "auto-syncs family if hasn't synced in last 24 hours" do
    # If request comes in at beginning of day, but last sync was 1 hour ago ("yesterday"), we still sync
    travel_to Time.current.beginning_of_day
    last_sync_datetime = 1.hour.ago

    Sync.create!(syncable: @family, created_at: last_sync_datetime)

    assert_difference "Sync.count", 1 do
      get root_path
    end
  end

  test "does not auto-sync if family has synced today already" do
    travel_to Time.current.end_of_day

    last_created_sync_at = 23.hours.ago

    Sync.create!(syncable: @family, created_at: last_created_sync_at)

    assert_no_difference "Sync.count" do
      get root_path
    end
  end
end
