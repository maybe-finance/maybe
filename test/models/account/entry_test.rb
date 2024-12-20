require "test_helper"

class Account::EntryTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @entry = account_entries :transaction
  end

  test "entry cannot be older than 10 years ago" do
    assert_raises ActiveRecord::RecordInvalid do
      @entry.update! date: 50.years.ago.to_date
    end
  end

  test "valuations cannot have more than one entry per day" do
    existing_valuation = account_entries :valuation

    new_valuation = Account::Entry.new \
      entryable: Account::Valuation.new,
      account: existing_valuation.account,
      date: existing_valuation.date, # invalid
      currency: existing_valuation.currency,
      amount: existing_valuation.amount

    assert new_valuation.invalid?
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
    @entry.destroy!

    @entry.account.expects(:sync_later).with(start_date: nil)
    @entry.sync_account_later
  end

  test "can search entries" do
    family = families(:empty)
    account = family.accounts.create! name: "Test", balance: 0, currency: "USD", accountable: Depository.new
    category = family.categories.first
    merchant = family.merchants.first

    create_transaction(account: account, name: "a transaction")
    create_transaction(account: account, name: "ignored")
    create_transaction(account: account, name: "third transaction", category: category, merchant: merchant)

    params = { search: "a" }

    assert_equal 2, family.entries.search(params).size

    params = { search: "%" }
    assert_equal 0, family.entries.search(params).size
  end

  test "can calculate total spending for a group of transactions" do
    family = families(:empty)
    account = family.accounts.create! name: "Test", balance: 0, currency: "USD", accountable: Depository.new
    create_transaction(account: account, amount: 100)
    create_transaction(account: account, amount: 100)
    create_transaction(account: account, amount: -500) # income, will be ignored

    assert_equal Money.new(200), family.entries.expense_total("USD")
  end

  test "can calculate total income for a group of transactions" do
    family = families(:empty)
    account = family.accounts.create! name: "Test", balance: 0, currency: "USD", accountable: Depository.new
    create_transaction(account: account, amount: -100)
    create_transaction(account: account, amount: -100)
    create_transaction(account: account, amount: 500) # income, will be ignored

    assert_equal Money.new(-200), family.entries.income_total("USD")
  end
end
