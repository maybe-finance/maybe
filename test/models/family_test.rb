require "test_helper"
require "csv"

class FamilyTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper
  include SyncableInterfaceTest

  def setup
    @family = families(:empty)
    @syncable = families(:dylan_family)
  end

  test "syncs plaid items and manual accounts" do
    family_sync = syncs(:family)

    manual_accounts_count = @syncable.accounts.manual.count
    items_count = @syncable.plaid_items.count

    Account.any_instance.expects(:sync_later)
      .with(start_date: nil)
      .times(manual_accounts_count)

    PlaidItem.any_instance.expects(:sync_later)
      .with(start_date: nil)
      .times(items_count)

    @syncable.sync_data(start_date: family_sync.start_date)
  end

  test "calculates assets" do
    assert_equal Money.new(0, @family.currency), @family.assets

    create_account(balance: 1000, accountable: Depository.new)
    create_account(balance: 5000, accountable: OtherAsset.new)
    create_account(balance: 10000, accountable: CreditCard.new) # ignored

    assert_equal Money.new(1000 + 5000, @family.currency), @family.assets
  end

  test "calculates liabilities" do
    assert_equal Money.new(0, @family.currency), @family.liabilities

    create_account(balance: 1000, accountable: CreditCard.new)
    create_account(balance: 5000, accountable: OtherLiability.new)
    create_account(balance: 10000, accountable: Depository.new) # ignored

    assert_equal Money.new(1000 + 5000, @family.currency), @family.liabilities
  end

  test "calculates net worth" do
    assert_equal Money.new(0, @family.currency), @family.net_worth

    create_account(balance: 1000, accountable: CreditCard.new)
    create_account(balance: 50000, accountable: Depository.new)

    assert_equal Money.new(50000 - 1000, @family.currency), @family.net_worth
  end

  test "should exclude disabled accounts from calculations" do
    cc = create_account(balance: 1000, accountable: CreditCard.new)
    create_account(balance: 50000, accountable: Depository.new)

    assert_equal Money.new(50000 - 1000, @family.currency), @family.net_worth

    cc.update! is_active: false

    assert_equal Money.new(50000, @family.currency), @family.net_worth
  end

  test "calculates snapshot" do
    asset = create_account(balance: 500, accountable: Depository.new)
    liability = create_account(balance: 100, accountable: CreditCard.new)

    asset.balances.create! date: 1.day.ago.to_date, currency: "USD", balance: 450
    asset.balances.create! date: Date.current, currency: "USD", balance: 500

    liability.balances.create! date: 1.day.ago.to_date, currency: "USD", balance: 50
    liability.balances.create! date: Date.current, currency: "USD", balance: 100

    expected_asset_series = [
      { date: 1.day.ago.to_date, value: Money.new(450) },
      { date: Date.current, value: Money.new(500) }
    ]

    expected_liability_series = [
      { date: 1.day.ago.to_date, value: Money.new(50) },
      { date: Date.current, value: Money.new(100) }
    ]

    expected_net_worth_series = [
      { date: 1.day.ago.to_date, value: Money.new(450 - 50) },
      { date: Date.current, value: Money.new(500 - 100) }
    ]

    assert_equal expected_asset_series, @family.snapshot[:asset_series].values.map { |v| { date: v.date, value: v.value } }
    assert_equal expected_liability_series, @family.snapshot[:liability_series].values.map { |v| { date: v.date, value: v.value } }
    assert_equal expected_net_worth_series, @family.snapshot[:net_worth_series].values.map { |v| { date: v.date, value: v.value } }
  end

  test "calculates top movers" do
    checking_account = create_account(balance: 500, accountable: Depository.new)
    savings_account = create_account(balance: 1000, accountable: Depository.new)
    create_transaction(account: checking_account, date: 2.days.ago.to_date, amount: -1000)
    create_transaction(account: checking_account, date: 1.day.ago.to_date, amount: 10)
    create_transaction(account: savings_account, date: 2.days.ago.to_date, amount: -5000)

    zero_income_zero_expense_account = create_account(balance: 200, accountable: Depository.new)
    create_transaction(account: zero_income_zero_expense_account, amount: 0)

    snapshot = @family.snapshot_account_transactions
    top_spenders = snapshot[:top_spenders]
    top_earners = snapshot[:top_earners]
    top_savers = snapshot[:top_savers]

    assert_equal [ 10 ], top_spenders.map(&:spending)
    assert_equal [ 5000, 1000 ], top_earners.map(&:income)
    assert_equal [ 1, 0.99 ], top_savers.map(&:savings_rate)
  end


  test "calculates rolling transaction totals" do
    account = create_account(balance: 1000, accountable: Depository.new)
    create_transaction(account: account, date: 2.days.ago.to_date, amount: -500)
    create_transaction(account: account, date: 1.day.ago.to_date, amount: 100)
    create_transaction(account: account, date: Date.current, amount: 20)

    snapshot = @family.snapshot_transactions

    expected_income_series = [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 500, 500, 500
    ]

    assert_equal expected_income_series, snapshot[:income_series].values.map(&:value).map(&:amount)

    expected_spending_series = [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 100, 120
    ]

    assert_equal expected_spending_series, snapshot[:spending_series].values.map(&:value).map(&:amount)

    expected_savings_rate_series = [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 1, 0.8, 0.76
    ]

    assert_equal expected_savings_rate_series, snapshot[:savings_rate_series].values.map(&:value).map { |v| v.round(2) }
  end

  private

    def create_account(attributes = {})
      account = @family.accounts.create! name: "Test", currency: "USD", **attributes
      account
    end
end
