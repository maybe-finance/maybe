require "test_helper"

class TransferTest < ActiveSupport::TestCase
  setup do
    # Transfers can be posted on different dates
    @outflow = accounts(:checking).transactions.create! date: 1.day.ago.to_date, name: "Transfer to Savings", amount: 100
    @inflow = accounts(:savings).transactions.create! date: Date.current, name: "Transfer from Savings", amount: -100
  end

  test "transfer valid if it has inflow and outflow from different accounts for the same amount" do
    transfer = Transfer.create! transactions: [ @inflow, @outflow ]

    assert transfer.valid?
  end

  test "transfer is valid with a single transaction" do
    transfer = Transfer.create! transactions: [ @outflow ]

    assert transfer.valid?
  end

  test "transfer cannot have more than 2 transactions" do
    unrelated_transaction = transactions :savings_four

    assert_raise ActiveRecord::RecordInvalid do
      Transfer.create! transactions: [ @inflow, @outflow, unrelated_transaction ]
    end
  end

  test "transfer cannot have 2 transactions from the same account" do
    account = accounts(:checking)
    inflow = account.transactions.create! date: Date.current, name: "Inflow", amount: -100
    outflow = account.transactions.create! date: Date.current, name: "Outflow", amount: 100

    assert_raise ActiveRecord::RecordInvalid do
      Transfer.create! transactions: [ inflow, outflow ]
    end
  end

  test "transfer transactions must net to zero" do
    @outflow.update! amount: 105

    assert_raises ActiveRecord::RecordInvalid do
      Transfer.create! transactions: [ @inflow, @outflow ]
    end
  end
end
