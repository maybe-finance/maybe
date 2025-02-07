require "test_helper"

class Account::SyncerTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(
      name: "Test",
      balance: 20000,
      cash_balance: 20000,
      currency: "USD",
      accountable: Investment.new
    )
  end

  test "converts foreign account balances and holdings to family currency" do
    @account.family.update! currency: "USD"
    @account.update! currency: "EUR"

    ExchangeRate.create!(date: 1.day.ago.to_date, from_currency: "EUR", to_currency: "USD", rate: 1.2)
    ExchangeRate.create!(date: Date.current, from_currency: "EUR", to_currency: "USD", rate: 2)

    Account::BalanceCalculator.any_instance.expects(:calculate).returns(
      [
        Account::Balance.new(date: 1.day.ago.to_date, balance: 1000, cash_balance: 1000, currency: "EUR"),
        Account::Balance.new(date: Date.current, balance: 1000, cash_balance: 1000, currency: "EUR")
      ]
    )

    Account::HoldingCalculator.any_instance.expects(:calculate).returns(
      [
        Account::Holding.new(security: securities(:aapl), date: 1.day.ago.to_date, qty: 10, price: 50, amount: 500, currency: "EUR"),
        Account::Holding.new(security: securities(:aapl), date: Date.current, qty: 10, price: 50, amount: 500, currency: "EUR")
      ]
    )

    Account::Syncer.new(@account).run

    assert_equal [ 1000, 1000 ], @account.balances.where(currency: "EUR").chronological.map(&:balance)
    assert_equal [ 1200, 2000 ], @account.balances.where(currency: "USD").chronological.map(&:balance)
    assert_equal [ 500, 500 ], @account.holdings.where(currency: "EUR").chronological.map(&:amount)
    assert_equal [ 600, 1000 ], @account.holdings.where(currency: "USD").chronological.map(&:amount)
  end

  test "purges stale balances and holdings" do
    # Old, out of range holdings and balances
    @account.holdings.create!(security: securities(:aapl), date: 10.years.ago.to_date, currency: "USD", qty: 100, price: 100, amount: 10000)
    @account.balances.create!(date: 10.years.ago.to_date, currency: "USD", balance: 10000, cash_balance: 10000)

    assert_equal 1, @account.holdings.count
    assert_equal 1, @account.balances.count

    Account::Syncer.new(@account).run

    @account.reload

    assert_equal 0, @account.holdings.count

    # Balance sync always creates 1 balance if no entries present.
    assert_equal 1, @account.balances.count
    assert_equal 0, @account.balances.first.balance
  end
end
