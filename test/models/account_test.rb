require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "auto_match_transfers_respects_existing_transfers" do
    # Create test accounts
    account1 = accounts(:checking)
    account2 = accounts(:savings)
    
    # Create matching transactions
    outflow = Account::Entry.create!(
      account: account1,
      date: Date.current,
      amount: 100,
      currency: "USD",
      entryable: Account::Transaction.create!
    )
    
    inflow = Account::Entry.create!(
      account: account2,
      date: Date.current,
      amount: -100,
      currency: "USD",
      entryable: Account::Transaction.create!
    )
    
    # Create initial transfer
    existing_transfer = Transfer.create!(
      inflow_transaction: inflow.entryable,
      outflow_transaction: outflow.entryable
    )
    
    # Verify no new transfers are created
    assert_no_difference 'Transfer.count' do
      account1.auto_match_transfers!
    end
  end

  test "auto_match_transfers_respects_rejected_transfers" do
    # Create test accounts
    account1 = accounts(:checking)
    account2 = accounts(:savings)
    
    # Create matching transactions
    outflow = Account::Entry.create!(
      account: account1,
      date: Date.current,
      amount: 100,
      currency: "USD",
      entryable: Account::Transaction.create!
    )
    
    inflow = Account::Entry.create!(
      account: account2,
      date: Date.current,
      amount: -100,
      currency: "USD",
      entryable: Account::Transaction.create!
    )
    
    # Create rejected transfer record
    RejectedTransfer.create!(
      inflow_transaction: inflow.entryable,
      outflow_transaction: outflow.entryable
    )
    
    # Verify no new transfers are created
    assert_no_difference 'Transfer.count' do
      account1.auto_match_transfers!
    end
  end
end
