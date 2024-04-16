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

  test "should prefill account when account_id is provided" do
    get new_transaction_url(account_id: accounts(:checking).id)
    assert_response :success
    assert_select "select[name=?]", "transaction[account_id]" do
      assert_select "option[selected][value=?]", accounts(:checking).id.to_s
    end
  end

  test "should create transaction" do
    name = "transaction_name"
    assert_difference("Transaction.count") do
      post transactions_url, params: { transaction: { account_id: @transaction.account_id, amount: @transaction.amount, currency: @transaction.currency, date: @transaction.date, name: } }
    end

    assert_redirected_to transactions_url
  end

  test "should ensure expense is positive" do
    assert_difference("Transaction.count") do
      post transactions_url, params: { transaction: { kind: "expense", account_id: @transaction.account_id, amount: 100, currency: @transaction.currency, date: @transaction.date, name: @transaction.name } }
    end

    assert_redirected_to transactions_url
    assert Transaction.order(created_at: :asc).last.amount.positive?, "Amount should be positive not #{Transaction.last.amount}"
  end

  test "should ensure income is negative" do
    assert_difference("Transaction.count") do
      post transactions_url, params: { transaction: { kind: "income", account_id: @transaction.account_id, amount: 100, currency: @transaction.currency, date: @transaction.date, name: @transaction.name } }
    end

    assert_redirected_to transactions_url
    assert Transaction.order(created_at: :asc).last.amount.negative?, "Amount should be negative"
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

  test "should destroy transaction" do
    assert_difference("Transaction.count", -1) do
      delete transaction_url(@transaction)
    end

    assert_redirected_to transactions_url
  end
end
