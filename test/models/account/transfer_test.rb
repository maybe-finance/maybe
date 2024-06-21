require "test_helper"

class Account::TransferTest < ActiveSupport::TestCase
  setup do
    # Transfers can be posted on different dates
    @outflow = accounts(:checking).transactions.create! date: 1.day.ago.to_date, name: "Transfer to Savings", amount: 100, marked_as_transfer: true
    @inflow = accounts(:savings).transactions.create! date: Date.current, name: "Transfer from Savings", amount: -100, marked_as_transfer: true
  end

  test "transfer valid if it has inflow and outflow from different accounts for the same amount" do
    transfer = Account::Transfer.create! transactions: [ @inflow, @outflow ]

    assert transfer.valid?
  end

  test "transfer must have 2 transactions" do
    invalid_transfer_1 = Account::Transfer.new transactions: [ @outflow ]
    invalid_transfer_2 = Account::Transfer.new transactions: [ @inflow, @outflow, transactions(:savings_four) ]

    assert invalid_transfer_1.invalid?
    assert invalid_transfer_2.invalid?
  end

  test "transfer cannot have 2 transactions from the same account" do
    account = accounts(:checking)
    inflow = account.transactions.create! date: Date.current, name: "Inflow", amount: -100
    outflow = account.transactions.create! date: Date.current, name: "Outflow", amount: 100

    assert_raise ActiveRecord::RecordInvalid do
      Account::Transfer.create! transactions: [ inflow, outflow ]
    end
  end

  test "all transfer transactions must be marked as transfers" do
    @inflow.update! marked_as_transfer: false

    assert_raise ActiveRecord::RecordInvalid do
      Account::Transfer.create! transactions: [ @inflow, @outflow ]
    end
  end

  test "single-currency transfer transactions must net to zero" do
    @outflow.update! amount: 105

    assert_raises ActiveRecord::RecordInvalid do
      Account::Transfer.create! transactions: [ @inflow, @outflow ]
    end
  end

  test "multi-currency transfer transactions do not have to net to zero" do
    @outflow.update! amount: 105, currency: "EUR"
    transfer = Account::Transfer.create! transactions: [ @inflow, @outflow ]

    assert transfer.valid?
  end
end
