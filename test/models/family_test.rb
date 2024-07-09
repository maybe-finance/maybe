require "test_helper"
require "csv"

class FamilyTest < ActiveSupport::TestCase
  def setup
    @family = families :dylan_family
  end

  test "calculates assets" do
    # collectable + checking + savings + eur_checking + multi_currency + brokerage + house + car
    assert_equal Money.new(613017, @family.currency), @family.assets
  end

  test "calculates liabilities" do
    # iou + credit_card + mortgage_loan
    assert_equal Money.new(501200, @family.currency), @family.liabilities
  end

  test "calculates net worth" do
    # assets - liabilities
    assert_equal Money.new(613017 - 501200, @family.currency), @family.net_worth
  end

  test "should exclude disabled accounts from calculations" do
    checking = accounts(:checking)
    original_checking_balance = checking.balance
    original_net_worth = 613017 - 501200

    checking.update! balance: 0

    assert_equal Money.new(original_net_worth - original_checking_balance, @family.currency), @family.net_worth
  end

  test "syncs active accounts" do
    checking_account = accounts(:checking)
    checking_account.update! is_active: false

    checking_account.expects(:sync_later).never

    Account.any_instance
           .expects(:sync_later)
           .with(start_date: nil)
           .times(@family.accounts.active.size)

    @family.sync
  end

  test "calculates snapshot" do
    Account::Balance.delete_all

    asset_account1 = accounts(:checking)
    asset_account1.balances.create! date: 1.day.ago.to_date, currency: "USD", balance: 4500
    asset_account1.balances.create! date: Date.current, currency: "USD", balance: 5000

    asset_account2 = accounts(:savings)
    asset_account2.balances.create! date: 1.day.ago.to_date, currency: "USD", balance: 15000
    asset_account2.balances.create! date: Date.current, currency: "USD", balance: 20000

    liability_account = accounts(:credit_card)
    liability_account.balances.create! date: 1.day.ago.to_date, currency: "USD", balance: 500
    liability_account.balances.create! date: Date.current, currency: "USD", balance: 1000

    expected_asset_series = [
      { date: 1.day.ago.to_date, value: Money.new(4500 + 15000) },
      { date: Date.current, value: Money.new(5000 + 20000) }
    ]

    expected_liability_series = [
      { date: 1.day.ago.to_date, value: Money.new(500) },
      { date: Date.current, value: Money.new(1000) }
    ]

    expected_net_worth_series = [
      { date: 1.day.ago.to_date, value: Money.new(4500 + 15000 - 500) },
      { date: Date.current, value: Money.new(5000 + 20000 - 1000) }
    ]

    assert_equal expected_asset_series, @family.snapshot[:asset_series].values.map { |v| { date: v.date, value: v.value } }
    assert_equal expected_liability_series, @family.snapshot[:liability_series].values.map { |v| { date: v.date, value: v.value } }
    assert_equal expected_net_worth_series, @family.snapshot[:net_worth_series].values.map { |v| { date: v.date, value: v.value } }
  end

  test "calculates top movers" do
    Account::Entry.delete_all

    checking_account = accounts(:checking)
    savings_account = accounts(:savings)

    create_transaction(checking_account, 2.days.ago.to_date, -1000) # income
    create_transaction(checking_account, 1.day.ago.to_date, 10) # expense

    create_transaction(savings_account, 2.days.ago.to_date, -5000) # income

    snapshot = @family.snapshot_account_transactions
    top_spenders = snapshot[:top_spenders]
    top_earners = snapshot[:top_earners]
    top_savers = snapshot[:top_savers]

    assert_equal checking_account.id, top_spenders.first.id
    assert_equal 10, top_spenders.first.spending

    assert_equal savings_account.id, top_earners.first.id
    assert_equal 5000, top_earners.first.income

    assert_equal checking_account.id, top_earners.second.id
    assert_equal 1000, top_earners.second.income

    assert_equal savings_account.id, top_savers.first.id
    assert_equal 1, top_savers.first.savings_rate

    assert_equal checking_account.id, top_savers.second.id
    assert_equal ((1000 - 10).to_f / 1000), top_savers.second.savings_rate
  end

  test "calculates rolling transaction totals" do
    create_transaction(accounts(:checking), 5.days.ago.to_date, 200)

    snapshot = @family.snapshot_transactions

    expected_income_series = [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 1500, 1500, 1500
    ]

    assert_equal expected_income_series, snapshot[:income_series].values.map(&:value).map(&:amount)

    expected_spending_series = [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 200,
      200, 200, 200, 210, 210
    ]

    assert_equal expected_spending_series, snapshot[:spending_series].values.map(&:value).map(&:amount)

    expected_savings_rate_series = [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0.87, 0.86, 0.86
    ]

    assert_equal expected_savings_rate_series, snapshot[:savings_rate_series].values.map(&:value).map { |v| v.round(2) }
  end

  private

    def create_transaction(account, date, amount)
      account.entries.create! \
        name: "txn",
        date: date,
        amount: amount,
        currency: @family.currency,
        entryable: Account::Transaction.new
    end
end
