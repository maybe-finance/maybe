require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  # See: https://github.com/maybe-finance/maybe/wiki/vision#signage-of-money
  test "negative amounts are inflows, positive amounts are outflows to an account" do
    inflow_transaction = transactions(:checking_four)
    outflow_transaction = transactions(:checking_five)

    assert inflow_transaction.amount < 0
    assert inflow_transaction.inflow?

    assert outflow_transaction.amount >= 0
    assert outflow_transaction.outflow?
  end
end
