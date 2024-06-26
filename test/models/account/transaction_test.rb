require "test_helper"

class Account::TransactionTest < ActiveSupport::TestCase
  setup do
    @transaction = account_transactions(:checking_one)
    @family = families(:dylan_family)
  end

  # See: https://github.com/maybe-finance/maybe/wiki/vision#signage-of-money
  test "negative amounts are inflows, positive amounts are outflows to an account" do
    inflow_transaction = account_transactions(:checking_four)
    outflow_transaction = account_transactions(:checking_five)

    assert inflow_transaction.entry.amount < 0
    assert inflow_transaction.inflow?

    assert outflow_transaction.entry.amount >= 0
    assert outflow_transaction.outflow?
  end

  test "can calculate total spending for a group of transactions" do
    assert_equal Money.new(2135), @family.transactions.expense_total("USD")
    assert_equal Money.new(1010.85, "EUR"), @family.transactions.expense_total("EUR")
  end

  test "can calculate total income for a group of transactions" do
    assert_equal -Money.new(2075), @family.transactions.income_total("USD")
    assert_equal -Money.new(250, "EUR"), @family.transactions.income_total("EUR")
  end
end
