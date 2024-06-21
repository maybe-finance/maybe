require "test_helper"

class Account::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_transactions(:checking_one)
    @recent_transactions = @user.family.transactions.ordered.limit(20).to_a
  end

  test "should get new" do
    get new_account_transaction_url
    assert_response :success
  end

  test "prefills account_id if provided" do
    get new_account_transaction_url(account_id: @transaction.account_id)
    assert_response :success
    assert_select "option[selected][value='#{@transaction.account_id}']"
  end

  test "should create transaction" do
    account = @user.family.accounts.first
    transaction_params = {
      account_id: account.id,
      amount: 100.45,
      currency: "USD",
      date: Date.current,
      name: "Test transaction"
    }

    assert_difference("Account::Transaction.count") do
      post account_transactions_url, params: { transaction: transaction_params }
    end

    assert_equal transaction_params[:amount].to_d, Account::Transaction.order(created_at: :desc).first.amount
    assert_equal "New transaction created successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
    assert_redirected_to transactions_url
  end

  test "expenses are positive" do
    assert_difference("Account::Transaction.count") do
      post account_transactions_url, params: { transaction: {
        nature: "expense",
        account_id: @transaction.account_id,
        amount: @transaction.amount,
        currency: @transaction.currency,
        date: @transaction.date,
        name: @transaction.name } }
    end

    assert_redirected_to transactions_url
    assert Account::Transaction.order(created_at: :desc).first.amount.positive?, "Amount should be positive"
  end

  test "incomes are negative" do
    assert_difference("Account::Transaction.count") do
      post account_transactions_url, params: {
        transaction: {
          nature: "income",
          account_id: @transaction.account_id,
          amount: @transaction.amount,
          currency: @transaction.currency,
          date: @transaction.date,
          name: @transaction.name
        }
      }
    end

    assert_redirected_to transactions_url
    assert Account::Transaction.order(created_at: :desc).first.amount.negative?, "Amount should be negative"
  end

  test "should show transaction" do
    get account_transaction_url(@transaction)
    assert_response :success
  end

  test "should update transaction" do
    patch account_transaction_url(@transaction), params: {
      transaction: {
        account_id: @transaction.account_id,
        amount: @transaction.amount,
        currency: @transaction.currency,
        date: @transaction.date,
        name: @transaction.name,
        tag_ids: [ Tag.first.id, Tag.second.id ]
      }
    }

    assert_redirected_to account_transaction_url(@transaction)
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "should destroy transaction" do
    assert_difference("Account::Transaction.count", -1) do
      delete account_transaction_url(@transaction)
    end

    assert_redirected_to transactions_url
    assert_enqueued_with(job: AccountSyncJob)
  end
end
