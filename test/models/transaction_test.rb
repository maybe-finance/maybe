require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  setup do
    @transaction = transactions(:checking_one)
  end

  # See: https://github.com/maybe-finance/maybe/wiki/vision#signage-of-money
  test "negative amounts are inflows, positive amounts are outflows to an account" do
    inflow_transaction = transactions(:checking_four)
    outflow_transaction = transactions(:checking_five)

    assert inflow_transaction.amount < 0
    assert inflow_transaction.inflow?

    assert outflow_transaction.amount >= 0
    assert outflow_transaction.outflow?
  end

  test "triggers sync with correct start date when transaction is set to prior date" do
    prior_date = @transaction.date - 1
    @transaction.update! date: prior_date

    @transaction.account.expects(:sync_later).with(prior_date)
    @transaction.sync_account_later
  end

  test "triggers sync with correct start date when transaction is set to future date" do
    prior_date = @transaction.date
    @transaction.update! date: @transaction.date + 1

    @transaction.account.expects(:sync_later).with(prior_date)
    @transaction.sync_account_later
  end

  test "triggers sync with correct start date when transaction deleted" do
    prior_transaction = transactions(:checking_two) # 12 days ago
    current_transaction = transactions(:checking_one) # 5 days ago
    current_transaction.destroy!

    current_transaction.account.expects(:sync_later).with(prior_transaction.date)
    current_transaction.sync_account_later
  end
end
