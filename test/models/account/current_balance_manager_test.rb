require "test_helper"

class Account::CurrentBalanceManagerTest < ActiveSupport::TestCase
  setup do
    @connected_account = accounts(:connected)  # Connected account - can update current balance
    @manual_account = accounts(:depository)  # Manual account - cannot update current balance
  end

  test "when no existing anchor, creates new anchor" do
    manager = Account::CurrentBalanceManager.new(@connected_account)

    assert_difference -> { @connected_account.entries.count } => 1,
                     -> { @connected_account.valuations.count } => 1 do
      result = manager.set_current_balance(1000)

      assert result.success?
      assert result.changes_made?
      assert_nil result.error
    end

    current_anchor = @connected_account.valuations.current_anchor.first
    assert_not_nil current_anchor
    assert_equal 1000, current_anchor.entry.amount
    assert_equal "current_anchor", current_anchor.kind

    entry = current_anchor.entry
    assert_equal 1000, entry.amount
    assert_equal Date.current, entry.date
    assert_equal "Current balance", entry.name  # Depository type returns "Current balance"
  end

  test "updates existing anchor" do
    # First create a current anchor
    manager = Account::CurrentBalanceManager.new(@connected_account)
    result = manager.set_current_balance(1000)
    assert result.success?

    current_anchor = @connected_account.valuations.current_anchor.first
    original_id = current_anchor.id
    original_entry_id = current_anchor.entry.id

    # Travel to tomorrow to ensure date change
    travel_to Date.current + 1.day do
      # Now update it
      assert_no_difference -> { @connected_account.entries.count } do
        assert_no_difference -> { @connected_account.valuations.count } do
          result = manager.set_current_balance(2000)
          assert result.success?
          assert result.changes_made?
        end
      end

      current_anchor.reload
      assert_equal original_id, current_anchor.id # Same valuation record
      assert_equal original_entry_id, current_anchor.entry.id # Same entry record
      assert_equal 2000, current_anchor.entry.amount
      assert_equal Date.current, current_anchor.entry.date # Should be updated to current date
    end
  end

  test "when manual account, raises InvalidOperation error" do
    manager = Account::CurrentBalanceManager.new(@manual_account)

    error = assert_raises(Account::CurrentBalanceManager::InvalidOperation) do
      manager.set_current_balance(1000)
    end

    assert_equal "Manual accounts cannot set current balance anchor. Set opening balance or use a reconciliation instead.", error.message

    # Verify no current anchor was created
    assert_nil @manual_account.valuations.current_anchor.first
  end

  test "when no changes made, returns success with no changes made" do
    # First create a current anchor
    manager = Account::CurrentBalanceManager.new(@connected_account)
    result = manager.set_current_balance(1000)
    assert result.success?
    assert result.changes_made?

    # Try to set the same value on the same date
    result = manager.set_current_balance(1000)

    assert result.success?
    assert_not result.changes_made?
    assert_nil result.error
  end

  test "updates only amount when balance changes" do
    manager = Account::CurrentBalanceManager.new(@connected_account)

    # Create initial anchor
    result = manager.set_current_balance(1000)
    assert result.success?

    current_anchor = @connected_account.valuations.current_anchor.first
    original_date = current_anchor.entry.date

    # Update only the balance
    result = manager.set_current_balance(1500)
    assert result.success?
    assert result.changes_made?

    current_anchor.reload
    assert_equal 1500, current_anchor.entry.amount
    assert_equal original_date, current_anchor.entry.date # Date should remain the same if on same day
  end

  test "updates date when called on different day" do
    manager = Account::CurrentBalanceManager.new(@connected_account)

    # Create initial anchor
    result = manager.set_current_balance(1000)
    assert result.success?

    current_anchor = @connected_account.valuations.current_anchor.first
    original_amount = current_anchor.entry.amount

    # Travel to tomorrow and update with same balance
    travel_to Date.current + 1.day do
      result = manager.set_current_balance(1000)
      assert result.success?
      assert result.changes_made? # Should be true because date changed

      current_anchor.reload
      assert_equal original_amount, current_anchor.entry.amount
      assert_equal Date.current, current_anchor.entry.date # Should be updated to new current date
    end
  end

  test "current_balance returns balance from current anchor" do
    manager = Account::CurrentBalanceManager.new(@connected_account)

    # Create a current anchor
    manager.set_current_balance(1500)

    # Should return the anchor's balance
    assert_equal 1500, manager.current_balance

    # Update the anchor
    manager.set_current_balance(2500)

    # Should return the updated balance
    assert_equal 2500, manager.current_balance
  end

  test "current_balance falls back to account balance when no anchor exists" do
    manager = Account::CurrentBalanceManager.new(@connected_account)

    # When no current anchor exists, should fall back to account.balance
    assert_equal @connected_account.balance, manager.current_balance
  end
end
