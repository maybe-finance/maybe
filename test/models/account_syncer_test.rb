require "test_helper"

class AccountSyncerTest < ActiveSupport::TestCase
    def setup
        depository = Account::Depository.create!
        @account = Account.create!(family: families(:dylan_family), name: "Test Checking Account", original_balance: 2000, accountable: depository)
    end

    test "syncs account with only transactions" do
        AccountSyncer.new(@account).sync
        flunk
    end

    test "syncs account with only valuations" do
        AccountSyncer.new(@account).sync
        flunk
    end

    test "syncs account with both valuations and transactions" do
        AccountSyncer.new(@account).sync
        flunk
    end

    test "syncs account from a specific start date" do
        AccountSyncer.new(@account).sync(start_date: Date.new(2021, 1, 1))
        flunk
    end
end
