require "test_helper"

class Account::SyncableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @account = accounts(:savings)
  end

  test "calculates effective start date of an account" do
    assert_equal 31.days.ago.to_date, accounts(:collectable).effective_start_date
    assert_equal 31.days.ago.to_date, @account.effective_start_date
  end

  test "syncs regular account" do
    @account.sync
    assert_equal "ok", @account.status
    assert_equal 32, @account.balances.count
  end

  test "syncs multi currency account" do
    required_exchange_rates_for_sync = [
      { from_currency: "EUR", to_currency: "USD", date: 4.days.ago.to_date, rate: 1.0788 },
      { from_currency: "EUR", to_currency: "USD", date: 19.days.ago.to_date, rate: 1.0822 }
    ]

    ExchangeRate.insert_all(required_exchange_rates_for_sync)

    account = accounts(:multi_currency)
    account.sync
    assert_equal "ok", account.status
    assert_equal 32, account.balances.where(currency: "USD").count
  end

  test "triggers sync job" do
    assert_enqueued_with(job: AccountSyncJob, args: [ @account, Date.current ]) do
      @account.sync_later(Date.current)
    end
  end

  test "account has no balances until synced" do
    account = accounts(:savings)

    assert_equal 0, account.balances.count
  end

  test "account has balances after syncing" do
    account = accounts(:savings)
    account.sync

    assert_equal 32, account.balances.count
  end

  test "partial sync with missing historical balances performs a full sync" do
    account = accounts(:savings)
    account.sync 10.days.ago.to_date

    assert_equal 32, account.balances.count
  end

  test "balances are updated after syncing" do
    account = accounts(:savings)
    balance_date = 10.days.ago
    account.balances.create!(date: balance_date, balance: 1000)
    account.sync

    assert_equal 19500, account.balances.find_by(date: balance_date)[:balance]
  end

  test "can perform a partial sync with a given sync start date" do
    # Perform a full sync to populate all balances
    @account.sync

    # Perform partial sync
    sync_start_date = 5.days.ago.to_date
    balances_before_sync = @account.balances.to_a
    @account.sync sync_start_date
    balances_after_sync = @account.reload.balances.to_a

    # Balances on or after should be updated
    balances_after_sync.each do |balance_after_sync|
      balance_before_sync = balances_before_sync.find { |b| b.date == balance_after_sync.date }

      if balance_after_sync.date >= sync_start_date
        assert balance_before_sync.updated_at < balance_after_sync.updated_at
      else
        assert_equal balance_before_sync.updated_at, balance_after_sync.updated_at
      end
    end
  end

  test "foreign currency account has balances in each currency after syncing" do
    required_exchange_rates_for_sync = [
      1.0834, 1.0845, 1.0819, 1.0872, 1.0788, 1.0743, 1.0755, 1.0774,
      1.0778, 1.0783, 1.0773, 1.0709, 1.0729, 1.0773, 1.0778, 1.078,
      1.0809, 1.0818, 1.0824, 1.0822, 1.0854, 1.0845, 1.0839, 1.0807,
      1.084, 1.0856, 1.0858, 1.0898, 1.095, 1.094, 1.0926, 1.0986
    ]

    required_exchange_rates_for_sync.each_with_index do |exchange_rate, idx|
      ExchangeRate.create! date: idx.days.ago.to_date, from_currency: "EUR", to_currency: "USD", rate: exchange_rate
    end

    account = accounts(:eur_checking)
    account.sync

    assert_equal 64, account.balances.count
    assert_equal 32, account.balances.where(currency: "EUR").count
    assert_equal 32, account.balances.where(currency: "USD").count
  end

  test "stale balances are purged after syncing" do
    account = accounts(:savings)

    # Create old, stale balances that should be purged (since they are before account start date)
    account.balances.create!(date: 1.year.ago, balance: 1000)
    account.balances.create!(date: 2.years.ago, balance: 2000)
    account.balances.create!(date: 3.years.ago, balance: 3000)

    account.sync

    assert_equal 32, account.balances.count
  end
end
