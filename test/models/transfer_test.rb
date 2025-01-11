require "test_helper"

class TransferTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @outflow = account_transactions(:transfer_out)
    @inflow = account_transactions(:transfer_in)
  end

  test "transfer has different accounts, opposing amounts, and within 4 days of each other" do
    outflow_entry = create_transaction(date: Date.current, account: accounts(:depository), amount: 500)
    inflow_entry = create_transaction(date: 1.day.ago.to_date, account: accounts(:credit_card), amount: -500)

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

  test "auto_match_for_account handles concurrent creation attempts" do
    account1 = accounts(:depository)
    account2 = accounts(:credit_card)
    
    t1 = create_transaction(date: Date.current, account: account1, amount: 500)
    t2 = create_transaction(date: Date.current, account: account2, amount: -500)

    # Simulate concurrent calls
    assert_difference -> { Transfer.count } => 1 do
      Thread.new { Transfer.auto_match_for_account(account1) }.join
      Thread.new { Transfer.auto_match_for_account(account2) }.join
    end

    # Verify only one transfer exists
    assert_equal 1, Transfer.where(
      inflow_transaction_id: t2.account_transaction.id,
      outflow_transaction_id: t1.account_transaction.id
    ).count
  end
end
