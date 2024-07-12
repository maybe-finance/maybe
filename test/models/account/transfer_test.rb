require "test_helper"

class Account::TransferTest < ActiveSupport::TestCase
  setup do
    @outflow = account_entries(:transfer_out)
    @inflow = account_entries(:transfer_in)
  end

  test "transfer valid if it has inflow and outflow from different accounts for the same amount" do
    transfer = Account::Transfer.create! entries: [ @inflow, @outflow ]

    assert transfer.valid?
  end

  test "transfer must have 2 transactions" do
    invalid_transfer_1 = Account::Transfer.new entries: [ @outflow ]
    invalid_transfer_2 = Account::Transfer.new entries: [ @inflow, @outflow, account_entries(:transaction) ]

    assert invalid_transfer_1.invalid?
    assert invalid_transfer_2.invalid?
  end

  test "transfer cannot have 2 transactions from the same account" do
    account = accounts(:depository)

    inflow = account.entries.create! \
      date: Date.current,
      name: "Inflow",
      amount: -100,
      currency: "USD",
      marked_as_transfer: true,
      entryable: Account::Transaction.new

    outflow = account.entries.create! \
      date: Date.current,
      name: "Outflow",
      amount: 100,
      currency: "USD",
      marked_as_transfer: true,
      entryable: Account::Transaction.new

    assert_raise ActiveRecord::RecordInvalid do
      Account::Transfer.create! entries: [ inflow, outflow ]
    end
  end

  test "all transfer transactions must be marked as transfers" do
    @inflow.update! marked_as_transfer: false

    assert_raise ActiveRecord::RecordInvalid do
      Account::Transfer.create! entries: [ @inflow, @outflow ]
    end
  end

  test "single-currency transfer transactions must net to zero" do
    @outflow.update! amount: 105

    assert_raises ActiveRecord::RecordInvalid do
      Account::Transfer.create! entries: [ @inflow, @outflow ]
    end
  end

  test "multi-currency transfer transactions do not have to net to zero" do
    @outflow.update! amount: 105, currency: "EUR"
    transfer = Account::Transfer.create! entries: [ @inflow, @outflow ]

    assert transfer.valid?
  end
end
