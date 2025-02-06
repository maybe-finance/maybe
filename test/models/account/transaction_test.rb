require "test_helper"

class Account::TransactionTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  test "can calculate totals for a group of transactions" do
    family = families(:empty)
    account = family.accounts.create! name: "Test", balance: 0, currency: "USD", accountable: Depository.new
    create_transaction(account: account, amount: 100)
    create_transaction(account: account, amount: 100)
    create_transaction(account: account, amount: -500)

    totals = family.transactions.stats("USD")

    assert_equal 3, totals.count
    assert_equal 500, totals.income_total
    assert_equal 200, totals.expense_total
    assert_equal "USD", totals.currency
  end
end
