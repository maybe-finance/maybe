require "test_helper"

class TransferMatcherTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @family = families(:dylan_family)
    @matcher = TransferMatcher.new(@family)
  end

  test "matches entries with opposite amounts and different accounts within 4 days" do
    entry1 = create_transaction(account: accounts(:depository), amount: 100, date: Date.current)
    entry2 = create_transaction(account: accounts(:credit_card), amount: -100, date: 2.days.ago.to_date)

    assert_difference "Account::Transfer.count", 1 do
      @matcher.match!([ entry1, entry2 ])
    end
  end

  test "doesn't match entries more than 4 days apart" do
    entry1 = create_transaction(account: accounts(:depository), amount: 100, date: Date.current)
    entry2 = create_transaction(account: accounts(:credit_card), amount: -100, date: Date.current + 5.days)

    assert_no_difference "Account::Transfer.count" do
      @matcher.match!([ entry1, entry2 ])
    end
  end
end
