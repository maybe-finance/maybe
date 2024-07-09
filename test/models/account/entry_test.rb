require "test_helper"

class Account::EntryTest < ActiveSupport::TestCase
  setup do
    @entry = account_entries :expense_transaction
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

    @entry.account.expects(:sync_later).with(start_date: prior_date)
    @entry.sync_account_later
  end

  test "triggers sync with correct start date when transaction is set to future date" do
    prior_date = @entry.date
    @entry.update! date: @entry.date + 1

    @entry.account.expects(:sync_later).with(start_date: prior_date)
    @entry.sync_account_later
  end

  test "triggers sync with correct start date when transaction deleted" do
    prior_entry = account_entries :income_transaction # 2 days ago
    current_entry = account_entries :expense_transaction # 1 day ago

    current_entry.destroy!

    current_entry.account.expects(:sync_later).with(start_date: prior_entry.date)
    current_entry.sync_account_later
  end

  test "can search entries" do
    Account::Entry.delete_all

    create_transaction("a transaction", 3.days.ago.to_date, 100)
    create_transaction("another transaction", 3.days.ago.to_date, 200)
    create_transaction("another transaction", 4.days.ago.to_date, 200, categories(:food_and_drink))

    params = { search: "a" }

    assert_equal 3, Account::Entry.search(params).size

    params = params.merge(categories: [ "Food & Drink" ]) # transaction specific search param

    assert_equal 1, Account::Entry.search(params).size
  end

  test "can calculate total spending for a group of transactions" do
    assert_equal Money.new(10), @family.entries.expense_total("USD")
  end

  test "can calculate total income for a group of transactions" do
    assert_equal Money.new(-1500), @family.entries.income_total("USD")
  end

  # See: https://github.com/maybe-finance/maybe/wiki/vision#signage-of-money
  test "transactions with negative amounts are inflows, positive amounts are outflows to an account" do
    inflow_transaction = account_entries :income_transaction
    outflow_transaction = account_entries :expense_transaction

    assert inflow_transaction.amount < 0
    assert inflow_transaction.inflow?

    assert outflow_transaction.amount >= 0
    assert outflow_transaction.outflow?
  end

  private

    def create_transaction(name, date, amount, category = nil, currency: "USD", account: accounts(:checking))
      account.entries.create! \
        date: date,
        amount: amount,
        currency: currency,
        name: name,
        entryable: Account::Transaction.new(category: category)
    end
end
