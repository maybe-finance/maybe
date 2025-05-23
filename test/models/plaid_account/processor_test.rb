require "test_helper"

class PlaidAccount::ProcessorTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)
  end

  test "processes new account and assigns attributes" do
    Account.destroy_all # Clear out internal accounts so we start fresh

    expect_default_subprocessor_calls

    @plaid_account.update!(
      plaid_id: "test_plaid_id",
      plaid_type: "depository",
      plaid_subtype: "checking",
      current_balance: 1000,
      available_balance: 1000,
      currency: "USD",
      name: "Test Plaid Account",
      mask: "1234"
    )

    assert_difference "Account.count" do
      PlaidAccount::Processor.new(@plaid_account).process
    end

    @plaid_account.reload

    account = Account.order(created_at: :desc).first
    assert_equal "Test Plaid Account", account.name
    assert_equal @plaid_account.id, account.plaid_account_id
    assert_equal "checking", account.subtype
    assert_equal 1000, account.balance
    assert_equal 1000, account.cash_balance
    assert_equal "USD", account.currency
    assert_equal "Depository", account.accountable_type
    assert_equal "checking", account.subtype
  end

  test "processing is idempotent with updates and enrichments" do
    expect_default_subprocessor_calls

    assert_equal "Plaid Depository Account", @plaid_account.account.name
    assert_equal "checking", @plaid_account.account.subtype

    @plaid_account.account.update!(
      name: "User updated name",
      subtype: "savings",
      balance: 2000 # User cannot override balance.  This will be overridden by the processor on next processing
    )

    @plaid_account.account.lock_attr!(:name)
    @plaid_account.account.lock_attr!(:subtype)
    @plaid_account.account.lock_attr!(:balance) # Even if balance somehow becomes locked, Plaid ignores it and overrides it

    assert_no_difference "Account.count" do
      PlaidAccount::Processor.new(@plaid_account).process
    end

    @plaid_account.reload

    assert_equal "User updated name", @plaid_account.account.name
    assert_equal "savings", @plaid_account.account.subtype
    assert_equal @plaid_account.current_balance, @plaid_account.account.balance # Overriden by processor
  end

  test "account processing failure halts further processing" do
    Account.any_instance.stubs(:save!).raises(StandardError.new("Test error"))

    PlaidAccount::Transactions::Processor.any_instance.expects(:process).never
    PlaidAccount::Investments::TransactionsProcessor.any_instance.expects(:process).never
    PlaidAccount::Investments::HoldingsProcessor.any_instance.expects(:process).never

    expect_no_investment_balance_calculator_calls
    expect_no_liability_processor_calls

    assert_raises(StandardError) do
      PlaidAccount::Processor.new(@plaid_account).process
    end
  end

  test "product processing failure reports exception and continues processing" do
    PlaidAccount::Transactions::Processor.any_instance.stubs(:process).raises(StandardError.new("Test error"))

    # Subsequent product processors still run
    expect_investment_product_processor_calls

    assert_nothing_raised do
      PlaidAccount::Processor.new(@plaid_account).process
    end
  end

  test "calculates balance using BalanceCalculator for investment accounts" do
    @plaid_account.update!(plaid_type: "investment")

    PlaidAccount::Investments::BalanceCalculator.any_instance.expects(:balance).returns(1000).once
    PlaidAccount::Investments::BalanceCalculator.any_instance.expects(:cash_balance).returns(1000).once

    PlaidAccount::Processor.new(@plaid_account).process
  end

  test "processes credit liability data" do
    expect_investment_product_processor_calls
    expect_no_investment_balance_calculator_calls
    expect_depository_product_processor_calls

    @plaid_account.update!(plaid_type: "credit", plaid_subtype: "credit card")

    PlaidAccount::Liabilities::CreditProcessor.any_instance.expects(:process).once
    PlaidAccount::Liabilities::MortgageProcessor.any_instance.expects(:process).never
    PlaidAccount::Liabilities::StudentLoanProcessor.any_instance.expects(:process).never

    PlaidAccount::Processor.new(@plaid_account).process
  end

  test "processes mortgage liability data" do
    expect_investment_product_processor_calls
    expect_no_investment_balance_calculator_calls
    expect_depository_product_processor_calls

    @plaid_account.update!(plaid_type: "loan", plaid_subtype: "mortgage")

    PlaidAccount::Liabilities::CreditProcessor.any_instance.expects(:process).never
    PlaidAccount::Liabilities::MortgageProcessor.any_instance.expects(:process).once
    PlaidAccount::Liabilities::StudentLoanProcessor.any_instance.expects(:process).never

    PlaidAccount::Processor.new(@plaid_account).process
  end

  test "processes student loan liability data" do
    expect_investment_product_processor_calls
    expect_no_investment_balance_calculator_calls
    expect_depository_product_processor_calls

    @plaid_account.update!(plaid_type: "loan", plaid_subtype: "student")

    PlaidAccount::Liabilities::CreditProcessor.any_instance.expects(:process).never
    PlaidAccount::Liabilities::MortgageProcessor.any_instance.expects(:process).never
    PlaidAccount::Liabilities::StudentLoanProcessor.any_instance.expects(:process).once

    PlaidAccount::Processor.new(@plaid_account).process
  end

  private
    def expect_investment_product_processor_calls
      PlaidAccount::Investments::TransactionsProcessor.any_instance.expects(:process).once
      PlaidAccount::Investments::HoldingsProcessor.any_instance.expects(:process).once
    end

    def expect_depository_product_processor_calls
      PlaidAccount::Transactions::Processor.any_instance.expects(:process).once
    end

    def expect_no_investment_balance_calculator_calls
      PlaidAccount::Investments::BalanceCalculator.any_instance.expects(:balance).never
      PlaidAccount::Investments::BalanceCalculator.any_instance.expects(:cash_balance).never
    end

    def expect_no_liability_processor_calls
      PlaidAccount::Liabilities::CreditProcessor.any_instance.expects(:process).never
      PlaidAccount::Liabilities::MortgageProcessor.any_instance.expects(:process).never
      PlaidAccount::Liabilities::StudentLoanProcessor.any_instance.expects(:process).never
    end

    def expect_default_subprocessor_calls
      expect_depository_product_processor_calls
      expect_investment_product_processor_calls
      expect_no_investment_balance_calculator_calls
      expect_no_liability_processor_calls
    end
end
