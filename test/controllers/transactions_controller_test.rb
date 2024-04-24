require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = transactions(:checking_one)
    @account = @transaction.account
  end

  test "should get index" do
    get transactions_url
    assert_response :success
  end

  test "should get new" do
    get new_transaction_url
    assert_response :success
  end

  test "prefills account_id if provided" do
    get new_transaction_url(account_id: @transaction.account_id)
    assert_response :success
    assert_select "option[selected][value='#{@transaction.account_id}']"
  end

  test "should create transaction" do
    name = "transaction_name"
    assert_difference("Transaction.count") do
      post transactions_url, params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: @transaction.date, name: } }
    end

    assert_redirected_to transactions_url
  end

  test "create should sync account with correct start date" do
    assert_enqueued_with(job: AccountSyncJob, args: [@account, @transaction.date]) do
      post transactions_url, params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: @transaction.date, name: @transaction.name } }
    end
  end

  test "creation preserves decimals" do
    assert_difference("Transaction.count") do
      post transactions_url, params: { transaction: {
        nature: "expense",
        account_id: @transaction.account_id,
        amount: 123.45,
        currency: @transaction.currency,
        date: @transaction.date,
        name: @transaction.name } }
    end

    assert_redirected_to transactions_url
    assert_equal 123.45.to_d, Transaction.order(created_at: :desc).first.amount
  end

  test "expenses are positive" do
    assert_difference("Transaction.count") do
      post transactions_url, params: { transaction: {
        nature: "expense",
        account_id: @transaction.account_id,
        amount: @transaction.amount,
        currency: @transaction.currency,
        date: @transaction.date,
        name: @transaction.name } }
    end

    assert_redirected_to transactions_url
    assert Transaction.order(created_at: :desc).first.amount.positive?, "Amount should be positive"
  end

  test "incomes are negative" do
    assert_difference("Transaction.count") do
      post transactions_url, params: { transaction: {
        nature: "income",
        account_id: @transaction.account_id,
        amount: @transaction.amount,
        currency: @transaction.currency,
        date: @transaction.date,
        name: @transaction.name } }
    end

    assert_redirected_to transactions_url
    assert Transaction.order(created_at: :desc).first.amount.negative?, "Amount should be negative"
  end

  test "should show transaction" do
    get transaction_url(@transaction)
    assert_response :success
  end

  test "should get edit" do
    get edit_transaction_url(@transaction)
    assert_response :success
  end

  test "should update transaction" do
    patch transaction_url(@transaction), params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: @transaction.date, name: @transaction.name } }
    assert_redirected_to transaction_url(@transaction)
  end

  test "update should sync account with correct start date" do
    new_date = @transaction.date - 1.day
    assert_enqueued_with(job: AccountSyncJob, args: [@account, new_date]) do
      patch transaction_url(@transaction), params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: new_date, name: @transaction.name } }
    end

    new_date = @transaction.reload.date + 1.day
    assert_enqueued_with(job: AccountSyncJob, args: [@account, @transaction.date]) do
      patch transaction_url(@transaction), params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: new_date, name: @transaction.name } }
    end
  end

  test "should destroy transaction" do
    assert_difference("Transaction.count", -1) do
      delete transaction_url(@transaction)
    end

    assert_redirected_to transactions_url
  end

  test "destroy should sync account with correct start date" do
    first, second = @transaction.account.transactions.order(:date).all

    assert_enqueued_with(job: AccountSyncJob, args: [@account, first.date]) do
      delete transaction_url(second)
    end

    assert_enqueued_with(job: AccountSyncJob, args: [@account, nil]) do
      delete transaction_url(first)
    end
  end
end
