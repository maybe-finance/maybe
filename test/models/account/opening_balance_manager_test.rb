require "test_helper"

class Account::OpeningBalanceManagerTest < ActiveSupport::TestCase
  setup do
    @depository_account = accounts(:depository)
    @investment_account = accounts(:investment)
  end

  test "when no existing anchor, creates new anchor" do
    manager = Account::OpeningBalanceManager.new(@depository_account)

    assert_difference -> { @depository_account.entries.count } => 1,
                     -> { @depository_account.valuations.count } => 1 do
      result = manager.set_opening_balance(
        balance: 1000,
        date: 1.year.ago.to_date
      )

      assert result.success?
      assert result.changes_made?
      assert_nil result.error
    end

    opening_anchor = @depository_account.valuations.opening_anchor.first
    assert_not_nil opening_anchor
    assert_equal 1000, opening_anchor.entry.amount
    assert_equal "opening_anchor", opening_anchor.kind

    entry = opening_anchor.entry
    assert_equal 1000, entry.amount
    assert_equal 1.year.ago.to_date, entry.date
    assert_equal "Opening balance", entry.name
  end

  test "when no existing anchor, creates with provided balance" do
    # Test with Depository account (should default to balance)
    depository_manager = Account::OpeningBalanceManager.new(@depository_account)

    assert_difference -> { @depository_account.valuations.count } => 1 do
      result = depository_manager.set_opening_balance(balance: 2000)
      assert result.success?
      assert result.changes_made?
    end

    depository_anchor = @depository_account.valuations.opening_anchor.first
    assert_equal 2000, depository_anchor.entry.amount

    # Test with Investment account (should default to 0)
    investment_manager = Account::OpeningBalanceManager.new(@investment_account)

    assert_difference -> { @investment_account.valuations.count } => 1 do
      result = investment_manager.set_opening_balance(balance: 5000)
      assert result.success?
      assert result.changes_made?
    end

    investment_anchor = @investment_account.valuations.opening_anchor.first
    assert_equal 5000, investment_anchor.entry.amount
  end

  test "when no existing anchor and no date provided, provides default based on account type" do
    # Test with recent entry (less than 2 years ago)
    @depository_account.entries.create!(
      date: 30.days.ago.to_date,
      name: "Test transaction",
      amount: 100,
      currency: "USD",
      entryable: Transaction.new
    )

    manager = Account::OpeningBalanceManager.new(@depository_account)

    assert_difference -> { @depository_account.valuations.count } => 1 do
      result = manager.set_opening_balance(balance: 1500)
      assert result.success?
      assert result.changes_made?
    end

    opening_anchor = @depository_account.valuations.opening_anchor.first
    # Default should be MIN(1 day before oldest entry, 2 years ago) = 2 years ago
    assert_equal 2.years.ago.to_date, opening_anchor.entry.date

    # Test with old entry (more than 2 years ago)
    loan_account = accounts(:loan)
    loan_account.entries.create!(
      date: 3.years.ago.to_date,
      name: "Old transaction",
      amount: 100,
      currency: "USD",
      entryable: Transaction.new
    )

    loan_manager = Account::OpeningBalanceManager.new(loan_account)

    assert_difference -> { loan_account.valuations.count } => 1 do
      result = loan_manager.set_opening_balance(balance: 5000)
      assert result.success?
      assert result.changes_made?
    end

    loan_anchor = loan_account.valuations.opening_anchor.first
    # Default should be MIN(3 years ago - 1 day, 2 years ago) = 3 years ago - 1 day
    assert_equal (3.years.ago.to_date - 1.day), loan_anchor.entry.date

    # Test with account that has no entries
    property_account = accounts(:property)
    manager_no_entries = Account::OpeningBalanceManager.new(property_account)

    assert_difference -> { property_account.valuations.count } => 1 do
      result = manager_no_entries.set_opening_balance(balance: 3000)
      assert result.success?
      assert result.changes_made?
    end

    opening_anchor_no_entries = property_account.valuations.opening_anchor.first
    # Default should be 2 years ago when no entries exist
    assert_equal 2.years.ago.to_date, opening_anchor_no_entries.entry.date
  end

  test "updates existing anchor" do
    # First create an opening anchor
    manager = Account::OpeningBalanceManager.new(@depository_account)
    result = manager.set_opening_balance(
      balance: 1000,
      date: 6.months.ago.to_date
    )
    assert result.success?

    opening_anchor = @depository_account.valuations.opening_anchor.first
    original_id = opening_anchor.id
    original_entry_id = opening_anchor.entry.id

    # Now update it
    assert_no_difference -> { @depository_account.entries.count } do
      assert_no_difference -> { @depository_account.valuations.count } do
        result = manager.set_opening_balance(
          balance: 2000,
          date: 8.months.ago.to_date
        )
        assert result.success?
        assert result.changes_made?
      end
    end

    opening_anchor.reload
    assert_equal original_id, opening_anchor.id # Same valuation record
    assert_equal original_entry_id, opening_anchor.entry.id # Same entry record
    assert_equal 2000, opening_anchor.entry.amount
    assert_equal 2000, opening_anchor.entry.amount
    assert_equal 8.months.ago.to_date, opening_anchor.entry.date
  end

  test "when existing anchor and no date provided, only update balance" do
    # First create an opening anchor
    manager = Account::OpeningBalanceManager.new(@depository_account)
    result = manager.set_opening_balance(
      balance: 1000,
      date: 3.months.ago.to_date
    )
    assert result.success?

    opening_anchor = @depository_account.valuations.opening_anchor.first

    # Update without providing date
    result = manager.set_opening_balance(balance: 1500)
    assert result.success?
    assert result.changes_made?

    opening_anchor.reload
    assert_equal 1500, opening_anchor.entry.amount
  end

  test "when existing anchor and updating balance only, preserves original date" do
    # First create an opening anchor with specific date
    manager = Account::OpeningBalanceManager.new(@depository_account)
    original_date = 4.months.ago.to_date
    result = manager.set_opening_balance(
      balance: 1000,
      date: original_date
    )
    assert result.success?

    opening_anchor = @depository_account.valuations.opening_anchor.first

    # Update without providing date
    result = manager.set_opening_balance(balance: 2500)
    assert result.success?
    assert result.changes_made?

    opening_anchor.reload
    assert_equal 2500, opening_anchor.entry.amount
    assert_equal original_date, opening_anchor.entry.date # Should remain unchanged
  end

  test "when date is equal to or greater than account's oldest entry, returns error result" do
    # Create an entry with a specific date
    oldest_date = 60.days.ago.to_date
    @depository_account.entries.create!(
      date: oldest_date,
      name: "Test transaction",
      amount: 100,
      currency: "USD",
      entryable: Transaction.new
    )

    manager = Account::OpeningBalanceManager.new(@depository_account)

    # Try to set opening balance on the same date as oldest entry
    result = manager.set_opening_balance(
      balance: 1000,
      date: oldest_date
    )

    assert_not result.success?
    assert_not result.changes_made?
    assert_equal "Opening balance date must be before the oldest entry date", result.error

    # Try to set opening balance after the oldest entry
    result = manager.set_opening_balance(
      balance: 1000,
      date: oldest_date + 1.day
    )

    assert_not result.success?
    assert_not result.changes_made?
    assert_equal "Opening balance date must be before the oldest entry date", result.error

    # Verify no opening anchor was created
    assert_nil @depository_account.valuations.opening_anchor.first
  end

  test "when no changes made, returns success with no changes made" do
    # First create an opening anchor
    manager = Account::OpeningBalanceManager.new(@depository_account)
    result = manager.set_opening_balance(
      balance: 1000,
      date: 2.months.ago.to_date
    )
    assert result.success?
    assert result.changes_made?

    # Try to set the same values
    result = manager.set_opening_balance(
      balance: 1000,
      date: 2.months.ago.to_date
    )

    assert result.success?
    assert_not result.changes_made?
    assert_nil result.error
  end
end
