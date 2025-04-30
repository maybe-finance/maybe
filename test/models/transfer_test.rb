require "test_helper"

class TransferTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @outflow = transactions(:transfer_out)
    @inflow = transactions(:transfer_in)
  end

  test "transfer destroyed if either transaction is destroyed" do
    assert_difference [ "Transfer.count", "Transaction.count", "Entry.count" ], -1 do
      @outflow.entry.destroy
    end
  end

  test "transfer has different accounts, opposing amounts, and within 4 days of each other" do
    outflow_entry = create_transaction(date: 1.day.ago.to_date, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)

    assert_difference -> { Transfer.count } => 1 do
      Transfer.create!(
        inflow_transaction: inflow_entry.transaction,
        outflow_transaction: outflow_entry.transaction,
      )
    end
  end

  test "transfer cannot have 2 transactions from the same account" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: 1.day.ago.to_date, account: accounts(:depository), amount: -500)

    transfer = Transfer.new(
      inflow_transaction: inflow_entry.transaction,
      outflow_transaction: outflow_entry.transaction,
    )

    assert_no_difference -> { Transfer.count } do
      transfer.save
    end

    assert_equal "Must be from different accounts", transfer.errors.full_messages.first
  end

  test "Transfer transactions must have opposite amounts" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -400)

    transfer = Transfer.new(
      inflow_transaction: inflow_entry.transaction,
      outflow_transaction: outflow_entry.transaction,
    )

    assert_no_difference -> { Transfer.count } do
      transfer.save
    end

    assert_equal "Must have opposite amounts", transfer.errors.full_messages.first
  end

  test "transfer dates must be within 4 days of each other" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: 5.days.ago.to_date, account: accounts(:credit_card), amount: -500)

    transfer = Transfer.new(
      inflow_transaction: inflow_entry.transaction,
      outflow_transaction: outflow_entry.transaction,
    )

    assert_no_difference -> { Transfer.count } do
      transfer.save
    end

    assert_equal "Must be within 4 days", transfer.errors.full_messages.first
  end

  test "transfer must be from the same family" do
    family1 = families(:empty)
    family2 = families(:dylan_family)

    family1_account = family1.accounts.create!(name: "Family 1 Account", balance: 5000, currency: "USD", accountable: Depository.new)
    family2_account = family2.accounts.create!(name: "Family 2 Account", balance: 5000, currency: "USD", accountable: Depository.new)

    outflow_txn = create_transaction(date: Date.current, account: family1_account, amount: 500)
    inflow_txn = create_transaction(date: Date.current, account: family2_account, amount: -500)

    transfer = Transfer.new(
      inflow_transaction: inflow_txn.transaction,
      outflow_transaction: outflow_txn.transaction,
    )

    assert transfer.invalid?
    assert_equal "Must be from same family", transfer.errors.full_messages.first
  end

  test "from_accounts converts amounts to the to_account's currency" do
    accounts(:depository).update!(currency: "EUR")

    eur_account = accounts(:depository).reload
    usd_account = accounts(:credit_card)

    ExchangeRate.create!(
      from_currency: "EUR",
      to_currency: "USD",
      rate: 1.1,
      date: Date.current,
    )

    transfer = Transfer.from_accounts(
      from_account: eur_account,
      to_account: usd_account,
      date: Date.current,
      amount: 500,
    )

    assert_equal 500, transfer.outflow_transaction.entry.amount
    assert_equal "EUR", transfer.outflow_transaction.entry.currency
    assert_equal -550, transfer.inflow_transaction.entry.amount
    assert_equal "USD", transfer.inflow_transaction.entry.currency

    assert_difference -> { Transfer.count } => 1 do
      transfer.save!
    end
  end

  test "transaction can only belong to one transfer" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry1 = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)
    inflow_entry2 = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)

    Transfer.create!(inflow_transaction: inflow_entry1.transaction, outflow_transaction: outflow_entry.transaction)

    assert_raises ActiveRecord::RecordInvalid do
      Transfer.create!(inflow_transaction: inflow_entry2.transaction, outflow_transaction: outflow_entry.transaction)
    end
  end
end
