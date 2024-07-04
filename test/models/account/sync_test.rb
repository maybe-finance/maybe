require "test_helper"

class Account::SyncTest < ActiveSupport::TestCase
  class MockSyncableBase
    include Syncable
  end

  setup do
    @account = accounts(:checking)
    @sync = Account::Sync.for(@account)
  end

  test "creates new sync with optional start date" do
    sync = Account::Sync.for(accounts(:checking), 10.days.ago.to_date)
    assert sync.valid?
    assert_equal 10.days.ago.to_date, sync.start_date
  end

  test "raises if passed unsyncable class" do
    class Unsyncable
      # Does not implement sync class method
    end

    assert_raises do
      @sync.start([ Unsyncable ])
    end
  end

  test "raises if syncable provides invalid response" do
    class InvalidSyncable
      def self.sync
        "invalid response"
      end
    end

    assert_raises do
      @sync.start([ InvalidSyncable ])
    end
  end

  test "can only run sync if in pending status" do
    class MockSyncable < MockSyncableBase
    end

    MockSyncable.expects(:sync).with(@account, start_date: nil).returns(Syncable::Response.new(success?: true)).once

    @sync.start([ MockSyncable ])
    assert_equal "completed", @sync.status

    assert_raises do
      @sync.start([ MockSyncable ])
    end
  end

  test "fails sync at first syncable error response" do
    class SuccessSyncable < MockSyncableBase
    end

    SuccessSyncable.expects(:sync)
                   .with(@account, start_date: nil)
                   .returns(Syncable::Response.new(success?: true))
                   .once

    class ErrorSyncable < MockSyncableBase
    end

    ErrorSyncable.expects(:sync)
                 .with(@account, start_date: nil)
                 .returns(Syncable::Response.new(success?: false, error: Syncable::Error.new("test sync error")))
                 .once

    @sync.start([ SuccessSyncable, ErrorSyncable, SuccessSyncable ])

    assert_equal "test sync error", @sync.error
    assert_equal "failed", @sync.status
  end

  test "warnings are appended and do not cause sync to stop" do
    class SuccessSyncable < MockSyncableBase
    end

    SuccessSyncable.expects(:sync)
                   .with(@account, start_date: nil)
                   .returns(Syncable::Response.new(success?: true, warnings: [ Syncable::Warning.new(message: "warning 1"), Syncable::Warning.new(message: "warning 2") ]))
                   .times(2)

    @sync.start([ SuccessSyncable, SuccessSyncable ])

    assert_equal 4, @sync.warnings.size
    assert_equal "completed", @sync.status
  end
end
