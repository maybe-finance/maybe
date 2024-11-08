require "test_helper"

class Account::SyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:depository)

    @sync = Account::Sync.for(@account)

    @balance_syncer = mock("Account::Balance::Syncer")
    @holding_syncer = mock("Account::Holding::Syncer")
  end

  test "runs sync" do
    Account::Balance::Syncer.expects(:new).with(@account, start_date: nil).returns(@balance_syncer).once
    Account::Holding::Syncer.expects(:new).with(@account, start_date: nil).returns(@holding_syncer).once

    @account.expects(:resolve_stale_issues).once
    @balance_syncer.expects(:run).once
    @holding_syncer.expects(:run).once

    assert_equal "pending", @sync.status
    assert_nil @sync.last_ran_at

    @sync.run

    streams = capture_turbo_stream_broadcasts [ @account.family, :notifications ]

    assert_equal "completed", @sync.status
    assert @sync.last_ran_at

    assert_equal "append", streams.first["action"]
    assert_equal "remove", streams.second["action"]
  end

  test "handles sync errors" do
    Account::Balance::Syncer.expects(:new).with(@account, start_date: nil).returns(@balance_syncer).once
    Account::Holding::Syncer.expects(:new).with(@account, start_date: nil).returns(@holding_syncer).never # error from balance sync halts entire sync

    @balance_syncer.expects(:run).raises(StandardError.new("test sync error"))

    @sync.run

    assert @sync.last_ran_at
    assert_equal "failed", @sync.status
    assert_equal "test sync error", @sync.error
  end
end
