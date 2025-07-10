require "test_helper"

class Account::OverviewFormTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:property)
  end

  test "initializes with account and attributes" do
    form = Account::OverviewForm.new(
      account: @account,
      name: "Updated Property"
    )

    assert_equal @account, form.account
    assert_equal "Updated Property", form.name
  end

  test "save returns result with success and updated status" do
    form = Account::OverviewForm.new(account: @account)
    result = form.save

    assert result.success?
    assert_not result.updated?
  end

  test "updates account name when provided" do
    form = Account::OverviewForm.new(
      account: @account,
      name: "New Property Name"
    )

    @account.expects(:update!).with(name: "New Property Name").once
    @account.expects(:sync_later).never  # Name change should not trigger sync

    result = form.save

    assert result.success?
    assert result.updated?
  end

  test "updates currency and triggers sync" do
    form = Account::OverviewForm.new(
      account: @account,
      currency: "EUR"
    )

    @account.expects(:update_currency!).with("EUR").once
    @account.expects(:sync_later).once  # Currency change should trigger sync

    result = form.save

    assert result.success?
    assert result.updated?
  end

  test "calls sync_later only once for multiple balance-related changes" do
    form = Account::OverviewForm.new(
      account: @account,
      currency: "EUR",
      opening_balance: 100_000,
      opening_cash_balance: 0,
      current_balance: 150_000,
      current_cash_balance: 0
    )

    @account.expects(:update_currency!).with("EUR").once
    @account.expects(:set_or_update_opening_balance!).once
    @account.expects(:update_current_balance!).once
    @account.expects(:sync_later).once  # Should only be called once despite multiple changes

    result = form.save

    assert result.success?
    assert result.updated?
  end

  test "does not call sync_later when transaction fails" do
    form = Account::OverviewForm.new(
      account: @account,
      name: "New Name",
      opening_balance: 100_000,
      opening_cash_balance: 0
    )

    # Simulate a validation error on opening balance update
    @account.expects(:update!).with(name: "New Name").once
    @account.expects(:set_or_update_opening_balance!).raises(Account::Reconcileable::InvalidBalanceError.new("Cash balance cannot exceed balance"))
    @account.expects(:sync_later).never  # Should NOT sync if any update fails

    result = form.save

    assert_not result.success?
    assert_not result.updated?
    assert_equal "Cash balance cannot exceed balance", result.error
  end

  test "raises ArgumentError when balance fields are not properly paired" do
    # Opening balance without cash balance
    form = Account::OverviewForm.new(
      account: @account,
      opening_balance: 100_000
    )

    # Debug what values we have
    assert_equal 100_000.to_d, form.opening_balance
    assert_nil form.opening_cash_balance

    error = assert_raises(ArgumentError) do
      form.save
    end
    assert_equal "Both opening_balance and opening_cash_balance must be provided together", error.message

    # Current cash balance without balance
    form = Account::OverviewForm.new(
      account: @account,
      current_cash_balance: 0
    )

    error = assert_raises(ArgumentError) do
      form.save
    end
    assert_equal "Both current_balance and current_cash_balance must be provided together", error.message
  end

  test "converts string balance values to decimals" do
    form = Account::OverviewForm.new(
      account: @account,
      opening_balance: "100000.50",
      opening_cash_balance: "0",
      current_balance: "150000.75",
      current_cash_balance: "5000.25"
    )

    assert_equal 100000.50.to_d, form.opening_balance
    assert_equal 0.to_d, form.opening_cash_balance
    assert_equal 150000.75.to_d, form.current_balance
    assert_equal 5000.25.to_d, form.current_cash_balance
  end
end
