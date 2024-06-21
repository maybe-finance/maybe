require "test_helper"

class Account::ValuationTest < ActiveSupport::TestCase
  setup do
    @valuation = account_valuations :savings_one
    @family = families :dylan_family
  end

  test "one valuation per day" do
    assert_equal 12.days.ago.to_date, account_valuations(:savings_one).date
    invalid_valuation = Account::Valuation.new date: 12.days.ago.to_date, value: 20000
    assert invalid_valuation.invalid?
  end

  test "triggers sync with correct start date when valuation is set to prior date" do
    prior_date = @valuation.date - 1
    @valuation.update! date: prior_date

    @valuation.account.expects(:sync_later).with(prior_date)
    @valuation.sync_account_later
  end

  test "triggers sync with correct start date when valuation is set to future date" do
    prior_date = @valuation.date
    @valuation.update! date: @valuation.date + 1

    @valuation.account.expects(:sync_later).with(prior_date)
    @valuation.sync_account_later
  end

  test "triggers sync with correct start date when valuation deleted" do
    prior_valuation = account_valuations :savings_two # 25 days ago
    current_valuation = account_valuations :savings_one # 12 days ago
    current_valuation.destroy!

    current_valuation.account.expects(:sync_later).with(prior_valuation.date)
    current_valuation.sync_account_later
  end
end
