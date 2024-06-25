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
end
