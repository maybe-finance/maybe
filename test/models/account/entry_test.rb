require "test_helper"

class Account::EntryTest < ActiveSupport::TestCase
  setup do
    @entry = account_entries :checking_one
    @family = families :dylan_family
  end

  test "valuations cannot have more than one entry per day" do
    new_entry = Account::Entry.new \
      entryable: Account::Valuation.new,
      date: @entry.date, # invalid
      currency: @entry.currency,
      amount: @entry.amount

    assert new_entry.invalid?
  end

  test "triggers sync with correct start date when transaction is set to prior date" do
    prior_date = @entry.date - 1
    @entry.update! date: prior_date

    @entry.account.expects(:sync_later).with(prior_date)
    @entry.sync_account_later
  end

  test "triggers sync with correct start date when transaction is set to future date" do
    prior_date = @entry.date
    @entry.update! date: @entry.date + 1

    @entry.account.expects(:sync_later).with(prior_date)
    @entry.sync_account_later
  end

  test "triggers sync with correct start date when transaction deleted" do
    prior_entry = account_entries(:checking_two) # 12 days ago
    current_entry = account_entries(:checking_one) # 5 days ago
    current_entry.destroy!

    current_entry.account.expects(:sync_later).with(prior_entry.date)
    current_entry.sync_account_later
  end

  test "can search entries" do
    params = { search: "a" }

    assert Account::Entry.search(params).size > 2

    params = params.merge(categories: [ "Food & Drink" ]) # transaction specific search param

    assert_equal 2, Account::Entry.search(params).size
  end

  test "can calculate total spending for a group of transactions" do
    assert_equal Money.new(2135), @family.entries.expense_total("USD")
    assert_equal Money.new(1010.85, "EUR"), @family.entries.expense_total("EUR")
  end

  test "can calculate total income for a group of transactions" do
    assert_equal -Money.new(2075), @family.entries.income_total("USD")
    assert_equal -Money.new(250, "EUR"), @family.entries.income_total("EUR")
  end

  # See: https://github.com/maybe-finance/maybe/wiki/vision#signage-of-money
  test "transactions with negative amounts are inflows, positive amounts are outflows to an account" do
    inflow_transaction = account_entries(:checking_four)
    outflow_transaction = account_entries(:checking_five)

    assert inflow_transaction.amount < 0
    assert inflow_transaction.inflow?

    assert outflow_transaction.amount >= 0
    assert outflow_transaction.outflow?
  end
end
