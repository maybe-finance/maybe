require "test_helper"

class Account::SyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:checking)
    @start_date = @account.effective_start_date

    @sync = Account::Sync.for(@account, start_date: @start_date)
    @balance_syncer = mock("Account::Balance::Syncer")
    Account::Balance::Syncer.expects(:new).with(@account, start_date: @start_date).returns(@balance_syncer).once
  end

  test "runs sync" do
    @balance_syncer.expects(:run).once

    assert_equal "pending", @sync.status

    @sync.run

    assert_equal "completed", @sync.status
  end

  test "handles sync errors" do
    @balance_syncer.expects(:run).raises(StandardError.new("test sync error"))

    @sync.run

    assert_equal "failed", @sync.status
    assert_equal "test sync error", @sync.error
  end
end
