require "test_helper"

class Account::Balance::SyncerTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(name: "Test", balance: 20000, currency: "USD", accountable: Depository.new)
    @investment_account = families(:empty).accounts.create!(name: "Test Investment", balance: 50000, currency: "USD", accountable: Investment.new)
  end

  test "syncs account with no entries" do
    assert_equal 0, @account.balances.count

    run_sync_for @account

    assert_equal [ @account.balance ], @account.balances.chronological.map(&:balance)
  end

  test "syncs account with valuations only" do
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 22000)

    run_sync_for @account

    assert_equal 22000, @account.balance
    assert_equal [ 22000, 22000, 22000 ], @account.balances.chronological.map(&:balance)
  end

  test "syncs account with transactions only" do
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: 100)
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -500)

    run_sync_for @account

    assert_equal 20000, @account.balance
    assert_equal [ 19600, 19500, 19500, 20000, 20000, 20000 ], @account.balances.chronological.map(&:balance)
  end

  test "syncs account with valuations and transactions" do
    create_valuation(account: @account, date: 5.days.ago.to_date, amount: 20000)
    create_transaction(account: @account, date: 3.days.ago.to_date, amount: -500)
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: 100)
    create_valuation(account: @account, date: 1.day.ago.to_date, amount: 25000)

    run_sync_for(@account)

    assert_equal 25000, @account.balance
    assert_equal [ 20000, 20000, 20500, 20400, 25000, 25000 ], @account.balances.chronological.map(&:balance)
  end

  test "syncs account with transactions in multiple currencies" do
    ExchangeRate.create! date: 1.day.ago.to_date, from_currency: "EUR", to_currency: "USD", rate: 1.2

    create_transaction(account: @account, date: 3.days.ago.to_date, amount: 100, currency: "USD")
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: 300, currency: "USD")
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: 500, currency: "EUR") # €500 * 1.2 = $600

    run_sync_for(@account)

    assert_equal 20000, @account.balance
    assert_equal [ 21000, 20900, 20600, 20000, 20000 ], @account.balances.chronological.map(&:balance)
  end

  test "converts foreign account balances to family currency" do
    @account.update! currency: "EUR"

    create_transaction(date: 1.day.ago.to_date, amount: 1000, account: @account, currency: "EUR")

    create_exchange_rate(2.days.ago.to_date, from: "EUR", to: "USD", rate: 2)
    create_exchange_rate(1.day.ago.to_date, from: "EUR", to: "USD", rate: 2)
    create_exchange_rate(Date.current, from: "EUR", to: "USD", rate: 2)

    with_env_overrides SYNTH_API_KEY: ENV["SYNTH_API_KEY"] || "fookey" do
      run_sync_for(@account)
    end

    usd_balances = @account.balances.where(currency: "USD").chronological.map(&:balance)
    eur_balances = @account.balances.where(currency: "EUR").chronological.map(&:balance)

    assert_equal 20000, @account.balance
    assert_equal [ 21000, 20000, 20000 ], eur_balances # native account balances
    assert_equal [ 42000, 40000, 40000 ], usd_balances # converted balances at rate of 2:1
  end

  test "raises issue if missing exchange rates" do
    create_transaction(date: Date.current, account: @account, currency: "EUR")

    ExchangeRate.expects(:find_rate).with(from: "EUR", to: "USD", date: Date.current).returns(nil)
    @account.expects(:observe_missing_exchange_rates).with(from: "EUR", to: "USD", dates: [ Date.current ])

    syncer = Account::Balance::Syncer.new(@account)

    syncer.run
  end

  # Account is able to calculate balances in its own currency (i.e. can still show a historical graph), but
  # doesn't have exchange rates available to convert those calculated balances to the family currency
  test "observes issue if exchange rate provider is not configured" do
    @account.update! currency: "EUR"

    syncer = Account::Balance::Syncer.new(@account)

    @account.expects(:observe_missing_exchange_rate_provider)

    with_env_overrides SYNTH_API_KEY: nil do
      syncer.run
    end
  end

  test "overwrites existing balances and purges stale balances" do
    assert_equal 0, @account.balances.size

    @account.balances.create! date: Date.current, currency: "USD", balance: 30000 # incorrect balance, will be updated
    @account.balances.create! date: 10.years.ago.to_date, currency: "USD", balance: 35000 # Out of range balance, will be deleted

    assert_equal 2, @account.balances.size

    run_sync_for(@account)

    assert_equal [ @account.balance ], @account.balances.chronological.map(&:balance)
  end

  test "partial sync does not affect balances prior to sync start date" do
    existing_balance = @account.balances.create! date: 2.days.ago.to_date, currency: "USD", balance: 30000

    transaction = create_transaction(account: @account, date: 1.day.ago.to_date, amount: 100, currency: "USD")

    run_sync_for(@account, start_date: 1.day.ago.to_date)

    assert_equal [ existing_balance.balance, existing_balance.balance - transaction.amount, @account.balance ], @account.balances.chronological.map(&:balance)
  end

  private

    def run_sync_for(account, start_date: nil)
      syncer = Account::Balance::Syncer.new(account, start_date: start_date)
      syncer.run
    end

    def create_exchange_rate(date, from:, to:, rate:)
      ExchangeRate.create! date: date, from_currency: from, to_currency: to, rate: rate
    end
end
