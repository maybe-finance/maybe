require "test_helper"

class Account::SyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:depository)

    @sync = Account::Sync.for(@account)
    @balance_syncer = mock("Account::Balance::Syncer")
    Account::Balance::Syncer.expects(:new).with(@account, start_date: nil).returns(@balance_syncer).once
  end

  test "runs sync" do
    @balance_syncer.expects(:run).once
    @balance_syncer.expects(:warnings).returns([ "test sync warning" ]).once

    assert_equal "pending", @sync.status
    assert_equal [], @sync.warnings
    assert_nil @sync.last_ran_at

    @sync.run

    assert_equal "completed", @sync.status
    assert_equal [ "test sync warning" ], @sync.warnings
    assert @sync.last_ran_at
  end

  test "handles sync errors" do
    @balance_syncer.expects(:run).raises(StandardError.new("test sync error"))

    @sync.run

    assert @sync.last_ran_at
    assert_equal "failed", @sync.status
    assert_equal "test sync error", @sync.error
  end
end
