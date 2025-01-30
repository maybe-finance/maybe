require "test_helper"

class TransferTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @outflow = account_transactions(:transfer_out)
    @inflow = account_transactions(:transfer_in)
  end

  test "transfer destroyed if either transaction is destroyed" do
    assert_difference [ "Transfer.count", "Account::Transaction.count", "Account::Entry.count" ], -1 do
      @outflow.entry.destroy
    end
  end

  test "transfer has different accounts, opposing amounts, and within 4 days of each other" do
    outflow_entry = create_transaction(date: 1.day.ago.to_date, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)

    assert_difference -> { Transfer.count } => 1 do
      Transfer.create!(
        inflow_transaction: inflow_entry.account_transaction,
        outflow_transaction: outflow_entry.account_transaction,
      )
    end
  end

  test "transfer cannot have 2 transactions from the same account" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: 1.day.ago.to_date, account: accounts(:depository), amount: -500)

    transfer = Transfer.new(
      inflow_transaction: inflow_entry.account_transaction,
      outflow_transaction: outflow_entry.account_transaction,
    )

    assert_no_difference -> { Transfer.count } do
      transfer.save
    end

    assert_equal "Transfer must have different accounts", transfer.errors.full_messages.first
  end

  test "Transfer transactions must have opposite amounts" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -400)

    transfer = Transfer.new(
      inflow_transaction: inflow_entry.account_transaction,
      outflow_transaction: outflow_entry.account_transaction,
    )

    assert_no_difference -> { Transfer.count } do
      transfer.save
    end

    assert_equal "Transfer transactions must have opposite amounts", transfer.errors.full_messages.first
  end

  test "transfer dates must be within 4 days of each other" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: 5.days.ago.to_date, account: accounts(:credit_card), amount: -500)

    transfer = Transfer.new(
      inflow_transaction: inflow_entry.account_transaction,
      outflow_transaction: outflow_entry.account_transaction,
    )

    assert_no_difference -> { Transfer.count } do
      transfer.save
    end

    assert_equal "Transfer transaction dates must be within 4 days of each other", transfer.errors.full_messages.first
  end

  test "transfer must be from the same family" do
    family1 = families(:empty)
    family2 = families(:dylan_family)

    family1_account = family1.accounts.create!(name: "Family 1 Account", balance: 5000, currency: "USD", accountable: Depository.new)
    family2_account = family2.accounts.create!(name: "Family 2 Account", balance: 5000, currency: "USD", accountable: Depository.new)

    outflow_txn = create_transaction(date: Date.current, account: family1_account, amount: 500)
    inflow_txn = create_transaction(date: Date.current, account: family2_account, amount: -500)

    transfer = Transfer.new(
      inflow_transaction: inflow_txn.account_transaction,
      outflow_transaction: outflow_txn.account_transaction,
    )

    assert transfer.invalid?
    assert_equal "Transfer must be from the same family", transfer.errors.full_messages.first
  end

  test "transaction can only belong to one transfer" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry1 = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)
    inflow_entry2 = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)

    Transfer.create!(inflow_transaction: inflow_entry1.account_transaction, outflow_transaction: outflow_entry.account_transaction)

    assert_raises ActiveRecord::RecordInvalid do
      Transfer.create!(inflow_transaction: inflow_entry2.account_transaction, outflow_transaction: outflow_entry.account_transaction)
    end
  end

  test "auto_match_transfers! does not create duplicate transfers" do
    account = accounts(:depository)
    existing_transfer = transfers(:existing_transfer)
    account_to_sync = existing_transfer.from_account

    assert_no_difference 'Transfer.count' do
      account_to_sync.auto_match_transfers!
    end
  end

  test "transfer_match_candidates excludes transactions already part of transfers" do
    account = accounts(:depository)
    existing_transfer = transfers(:existing_transfer)

    candidates = account.transfer_match_candidates

    existing_transaction_ids = Transfer.pluck(:inflow_transaction_id, :outflow_transaction_id).flatten

    candidates.each do |candidate|
      refute_includes existing_transaction_ids, candidate.inflow_transaction_id
      refute_includes existing_transaction_ids, candidate.outflow_transaction_id
    end
  end
end
