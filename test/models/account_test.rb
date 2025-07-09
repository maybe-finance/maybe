require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include SyncableInterfaceTest, EntriesTestHelper

  setup do
    @account = @syncable = accounts(:depository)
    @family = families(:dylan_family)
  end

  test "can destroy" do
    assert_difference "Account.count", -1 do
      @account.destroy
    end
  end

  test "gets short/long subtype label" do
    account = @family.accounts.create!(
      name: "Test Investment",
      balance: 1000,
      currency: "USD",
      subtype: "hsa",
      accountable: Investment.new
    )

    assert_equal "HSA", account.short_subtype_label
    assert_equal "Health Savings Account", account.long_subtype_label

    # Test with nil subtype
    account.update!(subtype: nil)
    assert_equal "Investments", account.short_subtype_label
    assert_equal "Investments", account.long_subtype_label
  end

  # Currency updates earn their own method because updating an account currency incurs
  # side effects like recalculating balances, etc.
  test "can update the account currency" do
    @account.update_currency!("EUR")

    assert_equal "EUR", @account.currency
    assert_equal "EUR", @account.entries.valuations.first.currency
  end

  # If a user has an opening balance (valuation) for their manual account and has 1+ transactions, the intent of
  # "updating current balance" typically means that their start balance is incorrect. We follow that user intent
  # by default and find the delta required, and update the opening balance so that the timeline reflects this current balance
  #
  # The purpose of this is so we're not cluttering up their timeline with "balance reconciliations" that reset the balance
  # on the current date. Our goal is to keep the timeline with as few "Valuations" as possible.
  #
  # If we ever build a UI that gives user options, this test expectation may require some updates, but for now this
  # is the least surprising outcome.
  test "when manual account has opening valuation and transactions, adjust opening balance directly with delta" do
    account = @family.accounts.create!(
      name: "Test",
      balance: 900, # the balance after opening valuation + transaction have "synced" (1000 - 100 = 900)
      cash_balance: 900,
      currency: "USD",
      accountable: Depository.new
    )

    account.entries.create!(
      date: 1.year.ago.to_date,
      name: "Test opening valuation",
      amount: 1000,
      currency: "USD",
      entryable: Valuation.new(
        kind: "opening_anchor",
        balance: 1000,
        cash_balance: 1000
      )
    )

    account.entries.create!(
      date: 10.days.ago.to_date,
      name: "Test expense transaction",
      amount: 100,
      currency: "USD",
      entryable: Transaction.new
    )

    # What we're asserting here:
    # 1. User creates the account with an opening balance of 1000
    # 2. User creates a transaction of 100, which then reduces the balance to 900 (the current balance value on account above)
    # 3. User requests "current balance update" back to 1000, which was their intention
    # 4. We adjust the opening balance by the delta (100) to 1100, which is the new opening balance, so that the transaction
    #    of 100 reduces it down to 1000, which is the current balance they intended.
    assert_equal 1, account.valuations.count
    assert_equal 1, account.transactions.count

    # No new valuation is appended; we're just adjusting the opening valuation anchor
    assert_no_difference "account.entries.count" do
      account.update_current_balance(balance: 1000, cash_balance: 1000)
    end

    opening_valuation = account.valuations.first

    assert_equal 1100, opening_valuation.balance
    assert_equal 1100, opening_valuation.cash_balance
  end

  # If the user has a "recon valuation" already (i.e. they applied a "balance override"), the most accurate thing we can do is append
  # a new recon valuation to the current day (i.e. "from this day forward, the balance is X"). Any other action risks altering the user's view
  # of their balance timeline and makes too many assumptions.
  test "when manual account has 1+ reconciling valuations, append a new recon valuation rather than adjusting opening balance" do
    account = @family.accounts.create!(
      name: "Test",
      balance: 1000,
      cash_balance: 1000,
      currency: "USD",
      accountable: Depository.new
    )

    account.entries.create!(
      date: 1.year.ago.to_date,
      name: "Test opening valuation",
      amount: 1000,
      currency: "USD",
      entryable: Valuation.new(
        kind: "opening_anchor",
        balance: 1000,
        cash_balance: 1000
      )
    )

    # User is "overriding" the balance to 1200 here
    account.entries.create!(
      date: 30.days.ago.to_date,
      name: "First manual recon valuation",
      amount: 1200,
      currency: "USD",
      entryable: Valuation.new(
        kind: "recon",
        balance: 1200,
        cash_balance: 1200
      )
    )

    assert_equal 2, account.valuations.count

    # Here, we assume user is once again "overriding" the balance to 1400
    account.update_current_balance(balance: 1400, cash_balance: 1400)

    most_recent_valuation = account.valuations.joins(:entry).order("entries.date DESC").first

    assert_equal 3, account.valuations.count
    assert_equal 1400, most_recent_valuation.balance
    assert_equal 1400, most_recent_valuation.cash_balance
  end

  # Updating "current balance" for a linked account is a pure system operation that manages the "current anchor" valuation
  test "updating current balance for linked account modifies current anchor valuation" do
    # TODO
  end

  # A recon valuation is an override for a user to "reset" the balance from a specific date forward.
  # This means, "The balance on X date is Y", which is then used as the new starting point to apply transactions against
  test "manual accounts can add recon valuations at any point in the account timeline" do
    assert_equal 1, @account.valuations.count

    @account.reconcile_balance!(balance: 1000, cash_balance: 1000, date: 2.days.ago.to_date)

    assert_equal 2, @account.valuations.count

    most_recent_valuation = @account.valuations.joins(:entry).order("entries.date DESC").first

    assert_equal 1000, most_recent_valuation.balance
    assert_equal 1000, most_recent_valuation.cash_balance
  end

  # While technically valid and possible to calculate, "recon" valuations for a linked account rarely make sense
  # and add complexity. If the user has linked to a data provider, we expect the provider to be responsible for
  # delivering the correct set of transactions to construct the historical balance
  test "recon valuations are invalid for linked accounts" do
    linked_account = accounts(:connected)

    assert_raises Account::InvalidBalanceError do
      linked_account.reconcile_balance!(balance: 1000, cash_balance: 1000, date: 2.days.ago.to_date)
    end
  end

  test "sets or updates opening balance" do
    Entry.destroy_all

    assert_equal 0, @account.entries.valuations.count

    # Creates non-existent opening valuation
    @account.set_or_update_opening_balance!(
      balance: 2000,
      cash_balance: 2000,
      date: 2.days.ago.to_date
    )

    opening_valuation_entry = @account.entries.first

    assert_equal 2000, opening_valuation_entry.amount
    assert_equal 2.days.ago.to_date, opening_valuation_entry.date
    assert_equal 2000, opening_valuation_entry.valuation.balance
    assert_equal 2000, opening_valuation_entry.valuation.cash_balance

    # Updates existing opening valuation
    @account.set_or_update_opening_balance!(
      balance: 3000,
      cash_balance: 3000
    )

    opening_valuation_entry = @account.entries.first

    assert_equal 3000, opening_valuation_entry.amount
    assert_equal 2.days.ago.to_date, opening_valuation_entry.date
    assert_equal 3000, opening_valuation_entry.valuation.balance
    assert_equal 3000, opening_valuation_entry.valuation.cash_balance
  end

  # While we don't allow "recon" valuations for a linked account, we DO allow opening balance updates. This is because
  # providers rarely give 100% of the transaction history (usually cuts off at 2 years), which can misrepresent the true
  # "opening date" on the account and obscure longer net worth historical graphs. This is an *optional* way for the user
  # to get their linked account histories "perfect".
  test "can update the opening balance and date for a linked account" do
    # TODO
  end

  test "can update the opening balance and date for a manual account" do
    # TODO
  end
end
