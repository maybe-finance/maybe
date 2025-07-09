require "test_helper"

class Family::AccountCreatableTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)
  end

  test "creates manual property account" do
    account = @family.create_property_account!(
      name: "My House",
      current_value: 450000,
      purchase_price: 400000,
      purchase_date: 1.year.ago.to_date
    )

    assert_opening_valuation(account: account, balance: 400000)
    assert_account_created_with(account: account, name: "My House", balance: 450000, cash_balance: 0)
  end

  test "creates manual vehicle account" do
    account = @family.create_vehicle_account!(
      name: "My Car",
      current_value: 25000,
      purchase_price: 30000,
      purchase_date: 2.years.ago.to_date
    )

    assert_opening_valuation(account: account, balance: 30000)
    assert_account_created_with(account: account, name: "My Car", balance: 25000, cash_balance: 0)
  end

  test "creates manual depository account" do
    account = @family.create_depository_account!(
      name: "My Checking",
      current_balance: 5000,
      opening_date: 1.year.ago.to_date
    )

    assert_opening_valuation(account: account, balance: 5000, cash_balance: 5000)
    assert_account_created_with(account: account, name: "My Checking", balance: 5000, cash_balance: 5000)
  end

  test "creates manual investment account" do
    account = @family.create_investment_account!(
      name: "My Brokerage"
    )

    assert_opening_valuation(account: account, balance: 0, cash_balance: 0)
    assert_account_created_with(account: account, name: "My Brokerage", balance: 0, cash_balance: 0)
  end

  test "creates manual other asset account" do
    account = @family.create_other_asset_account!(
      name: "Collectible",
      current_value: 10000,
      purchase_price: 5000,
      purchase_date: 3.years.ago.to_date
    )

    assert_opening_valuation(account: account, balance: 5000)
    assert_account_created_with(account: account, name: "Collectible", balance: 10000, cash_balance: 0)
  end

  test "creates manual other liability account" do
    account = @family.create_other_liability_account!(
      name: "Personal Loan",
      current_debt: 5000,
      original_debt: 10000,
      origination_date: 2.years.ago.to_date
    )

    assert_opening_valuation(account: account, balance: 10000)
    assert_account_created_with(account: account, name: "Personal Loan", balance: 5000, cash_balance: 0)
  end

  test "creates manual crypto account" do
    account = @family.create_crypto_account!(
      name: "Bitcoin Wallet",
      current_value: 50000
    )

    assert_opening_valuation(account: account, balance: 50000, cash_balance: 50000)
    assert_account_created_with(account: account, name: "Bitcoin Wallet", balance: 50000, cash_balance: 50000)
  end

  test "creates manual credit card account" do
    account = @family.create_credit_card_account!(
      name: "Visa Card",
      current_debt: 2000,
      opening_date: 6.months.ago.to_date
    )

    assert_opening_valuation(account: account, balance: 0, cash_balance: 0)
    assert_account_created_with(account: account, name: "Visa Card", balance: 2000, cash_balance: 0)
  end

  test "creates manual loan account" do
    account = @family.create_loan_account!(
      name: "Home Mortgage",
      current_principal: 200000,
      original_principal: 250000,
      origination_date: 5.years.ago.to_date
    )

    assert_opening_valuation(account: account, balance: 250000)
    assert_account_created_with(account: account, name: "Home Mortgage", balance: 200000, cash_balance: 0)
  end

  test "creates property account without purchase price" do
    account = @family.create_property_account!(
      name: "My House",
      current_value: 500000
    )

    assert_opening_valuation(account: account, balance: 500000)
    assert_account_created_with(account: account, name: "My House", balance: 500000, cash_balance: 0)
  end

  test "creates linked depository account" do
    # TODO
  end

  test "creates linked investment account" do
    # TODO
  end

  test "creates linked credit card account" do
    # TODO
  end

  test "creates linked loan account" do
    # TODO
  end

  private
    def assert_account_created_with(account:, name:, balance:, cash_balance:)
      assert_equal name, account.name
      assert_equal balance, account.balance
      assert_equal cash_balance, account.cash_balance
    end

    def assert_opening_valuation(account:, balance:, cash_balance: 0)
      valuations = account.valuations
      assert_equal 1, valuations.count

      opening_valuation = valuations.first
      assert_equal "opening_anchor", opening_valuation.kind
      assert_equal balance, opening_valuation.balance
      assert_equal cash_balance, opening_valuation.cash_balance
    end
end
