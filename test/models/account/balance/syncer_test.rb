require "test_helper"

class Account::Balance::SyncerTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:savings)
  end

  test "syncs account with no entries" do
    assert_equal 0, @account.balances.count

    syncer = Account::Balance::Syncer.new(@account)
    syncer.run

    assert_equal [ @account.balance ], balance_amounts
  end

  test "syncs account with valuations only" do
    create_valuation(2.days.ago.to_date, 22000)

    syncer = Account::Balance::Syncer.new(@account)
    syncer.run

    assert_equal [ 22000, 22000, @account.balance ], balance_amounts
  end

  test "syncs account with transactions only" do
    create_transaction(4.days.ago.to_date, 100)
    create_transaction(2.days.ago.to_date, -500)

    syncer = Account::Balance::Syncer.new(@account)
    syncer.run

    assert_equal [ 19600, 19500, 19500, 20000, 20000, @account.balance ], balance_amounts
  end

  test "syncs account with valuations and transactions" do
    create_valuation(5.days.ago.to_date, 20000)
    create_transaction(3.days.ago.to_date, -500)
    create_transaction(2.days.ago.to_date, 100)
    create_valuation(1.day.ago.to_date, 25000)

    syncer = Account::Balance::Syncer.new(@account)
    syncer.run

    assert_equal [ 20000, 20000, 20500, 20400, 25000, @account.balance ], balance_amounts
  end

  test "syncs account with transactions in multiple currencies" do
    ExchangeRate.create! date: 1.day.ago.to_date, from_currency: "EUR", to_currency: "USD", rate: 1.2

    create_transaction(3.days.ago.to_date, 100, currency: "USD")
    create_transaction(2.days.ago.to_date, 300, currency: "USD")
    create_transaction(1.day.ago.to_date, 500, currency: "EUR") # €500 * 1.2 = $600

    syncer = Account::Balance::Syncer.new(@account)
    syncer.run

    assert_equal [ 21000, 20900, 20600, 20000, @account.balance ], balance_amounts
  end

  test "converts foreign account balances to family currency" do
    foreign_account = accounts(:eur_checking)

    create_transaction(1.day.ago.to_date, 100, account: foreign_account, currency: "EUR")

    create_exchange_rate(2.days.ago.to_date, from: "EUR", to: "USD", rate: 2)
    create_exchange_rate(1.day.ago.to_date, from: "EUR", to: "USD", rate: 2)
    create_exchange_rate(Date.current, from: "EUR", to: "USD", rate: 2)

    syncer = Account::Balance::Syncer.new(foreign_account)
    syncer.run

    usd_balances = foreign_account.balances.where(currency: "USD").chronological.map(&:balance)
    eur_balances = foreign_account.balances.where(currency: "EUR").chronological.map(&:balance)

    assert_equal [ 12100, 12000, foreign_account.balance ], eur_balances # native account balances
    assert_equal [ 24200, 24000, foreign_account.balance * 2 ], usd_balances # converted balances at rate of 2:1
  end

  test "fails with error if exchange rate not available for any entry" do
    create_transaction(1.day.ago.to_date, 100, currency: "EUR")

    syncer = Account::Balance::Syncer.new(@account)

    assert_raises Money::ConversionError do
      syncer.run
    end
  end

  # Account is able to calculate balances in its own currency (i.e. can still show a historical graph), but
  # doesn't have exchange rates available to convert those calculated balances to the family currency
  test "completes with warning if exchange rates not available to convert to family currency" do
    foreign_account = accounts(:eur_checking)

    syncer = Account::Balance::Syncer.new(foreign_account)
    syncer.run

    assert_equal 1, syncer.warnings.count
  end

  test "overwrites existing balances and purges stale balances" do
    assert_equal 0, @account.balances.size

    @account.balances.create! date: Date.current, currency: "USD", balance: 30000 # incorrect balance, will be updated
    @account.balances.create! date: 10.years.ago.to_date, currency: "USD", balance: 35000 # Out of range balance, will be deleted

    assert_equal 2, @account.balances.size

    syncer = Account::Balance::Syncer.new(@account)
    syncer.run

    assert_equal [ @account.balance ], balance_amounts
  end

  test "partial sync does not affect balances prior to sync start date" do
    existing_balance = @account.balances.create! date: 2.days.ago.to_date, currency: "USD", balance: 30000

    transaction = create_transaction(1.day.ago.to_date, 100, currency: "USD")

    syncer = Account::Balance::Syncer.new(@account, start_date: 1.day.ago.to_date)
    syncer.run

    assert_equal [ existing_balance.balance, existing_balance.balance - transaction.amount, @account.balance ], balance_amounts
  end

  private

    def balance_amounts
      @account.balances.chronological.map(&:balance)
    end

    def create_exchange_rate(date, from:, to:, rate:)
      ExchangeRate.create! date: date, from_currency: from, to_currency: to, rate: rate
    end

    def create_transaction(date, amount, currency: "USD", account: @account)
      account.entries.create! \
        date: date,
        amount: amount,
        currency: currency,
        name: "txn",
        entryable: Account::Transaction.new
    end

    def create_valuation(date, amount)
      @account.entries.create! \
        date: date,
        amount: amount,
        currency: "USD",
        name: "valuation",
        entryable: Account::Valuation.new
    end
end
