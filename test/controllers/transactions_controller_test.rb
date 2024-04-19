require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = transactions(:checking_one)
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

  test "should sync account after create" do
    name = "transaction_name"
    account = @transaction.account
    date = @transaction.date
    amount_difference = @transaction.amount

    account.sync

    assert_difference("account.balance_on(date - 1.day)", amount_difference) do
      post transactions_url, params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: @transaction.date, name: } }
      perform_enqueued_jobs
    end
  end

  test "should do a partial account sync after create" do
    name = "transaction_name"
    account = @transaction.account
    date = @transaction.date

    account.sync
    account.balances.where(date: date - 10.day).update!(balance: 200)

    assert_no_changes("account.balance_on(date - 10.day)") do
      post transactions_url, params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: @transaction.date, name: } }
      perform_enqueued_jobs
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

  test "should sync account after update" do
    account = @transaction.account
    date = @transaction.date
    amount_difference = 20
    new_amount = @transaction.amount + amount_difference

    account.sync

    assert_difference("account.balance_on(date - 1.day)", amount_difference) do
      patch transaction_url(@transaction), params: { transaction: { account_id: @transaction.account_id, amount: new_amount, currency: @transaction.currency, date: @transaction.date, name: @transaction.name } }
      perform_enqueued_jobs
    end
  end

  test "should do a partial account sync after update" do
    account = @transaction.account
    date = @transaction.date

    account.sync
    account.balances.where(date: date - 10.day).update!(balance: 200)

    assert_no_changes("account.balance_on(date - 10.day)") do
      patch transaction_url(@transaction), params: { transaction: { account_id: @transaction.account_id, amount: @transaction.account, currency: @transaction.currency, date: @transaction.date, name: @transaction.name } }
      perform_enqueued_jobs
    end
  end

  test "should destroy transaction" do
    assert_difference("Transaction.count", -1) do
      delete transaction_url(@transaction)
    end

    assert_redirected_to transactions_url
  end

  test "should sync account after destroy" do
    account = @transaction.account
    date = @transaction.date
    amount = @transaction.amount

    account.sync

    assert_difference("account.balance_on(date - 1.day)", -amount) do
      delete transaction_url(@transaction)
      perform_enqueued_jobs
    end
  end

  test "should do a partial account sync after destroy" do
    account = @transaction.account
    date = @transaction.date

    account.sync
    account.balances.where(date: date - 10.day).update!(balance: 200)

    assert_no_changes("account.balance_on(date - 10.day)") do
      delete transaction_url(@transaction)
      perform_enqueued_jobs
    end
  end
end
