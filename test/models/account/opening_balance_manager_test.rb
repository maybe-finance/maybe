require "test_helper"

class Account::OpeningBalanceManagerTest < ActiveSupport::TestCase
  test "when no existing anchor, creates new anchor" do
  end

  test "when no existing anchor and no cash balance provided, provides default based on balance and account type" do
  end

  test "when no existing anchor and no date provided, provides default based on account type" do
  end

  test "updates existing anchor" do
  end

  test "when existing anchor and no cash balance provided, only update balance" do
  end

  test "when existing anchor and no date provided, only update balance" do
  end

  test "when date is equal to or greater than account's oldest entry, returns error result" do
  end

  test "when no changes made, returns success but doesn't re-sync account" do
  end
end
