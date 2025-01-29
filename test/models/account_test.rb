require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  test "transfer_match_candidates excludes transactions already used in transfers" do
    family = families(:empty)
    account1 = family.accounts.create!(name: "Account 1", balance: 5000, currency: "USD", accountable: Depository.new)
    account2 = family.accounts.create!(name: "Account 2", balance: 5000, currency: "USD", accountable: Depository.new)
    
    tx1 = create_transaction(date: Date.current, account: account1, amount: -500)
    tx2 = create_transaction(date: Date.current, account: account2, amount: 500)
    tx3 = create_transaction(date: Date.current, account: account1, amount: -500)
    tx4 = create_transaction(date: Date.current, account: account2, amount: 500)

    # Create an initial transfer
    Transfer.create!(
      inflow_transaction: tx1.account_transaction,
      outflow_transaction: tx2.account_transaction
    )

    # Verify that tx1 and tx2 are not included in match candidates
    candidates = account1.transfer_match_candidates
    assert_not_includes candidates.map(&:inflow_transaction_id), tx1.account_transaction.id
    assert_not_includes candidates.map(&:outflow_transaction_id), tx2.account_transaction.id
  end

  test "auto_match_transfers! creates transfers for matching transactions" do
    family = families(:empty)
    account1 = family.accounts.create!(name: "Account 1", balance: 5000, currency: "USD", accountable: Depository.new)
    account2 = family.accounts.create!(name: "Account 2", balance: 5000, currency: "USD", accountable: Depository.new)
    
    tx1 = create_transaction(date: Date.current, account: account1, amount: -500)
    tx2 = create_transaction(date: Date.current, account: account2, amount: 500)

    assert_difference -> { Transfer.count }, 1 do
      account1.auto_match_transfers!
    end

    transfer = Transfer.last
    assert_equal tx1.account_transaction.id, transfer.inflow_transaction_id
    assert_equal tx2.account_transaction.id, transfer.outflow_transaction_id
  end

  test "auto_match_transfers! handles multiple matching transactions correctly" do
    family = families(:empty)
    account1 = family.accounts.create!(name: "Account 1", balance: 5000, currency: "USD", accountable: Depository.new)
    account2 = family.accounts.create!(name: "Account 2", balance: 5000, currency: "USD", accountable: Depository.new)
    account3 = family.accounts.create!(name: "Account 3", balance: 5000, currency: "USD", accountable: Depository.new)

    tx1 = create_transaction(date: Date.current, account: account1, amount: -500)
    tx2 = create_transaction(date: Date.current, account: account2, amount: 500)
    tx3 = create_transaction(date: Date.current, account: account2, amount: -500)
    tx4 = create_transaction(date: Date.current, account: account3, amount: 500)

    assert_difference -> { Transfer.count }, 2 do
      account1.auto_match_transfers!
    end

    transfers = Transfer.last(2)
    assert_equal [tx1.account_transaction.id, tx3.account_transaction.id].sort, transfers.map(&:inflow_transaction_id).sort
    assert_equal [tx2.account_transaction.id, tx4.account_transaction.id].sort, transfers.map(&:outflow_transaction_id).sort
  end
end
