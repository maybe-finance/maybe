require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_transactions(:checking_one)
    @recent_transactions = @user.family.transactions.ordered.limit(20).to_a
  end

  test "should get new" do
    get new_transaction_url
    assert_response :success
  end

  test "prefills account_id" do
    get new_transaction_url(account_id: @transaction.account.id)
    assert_response :success
    assert_select "option[selected][value='#{@transaction.account.id}']"
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
      post transactions_url, params: { transaction: transaction_params }
    end

    assert_equal transaction_params[:amount].to_d, Account::Transaction.order(created_at: :desc).first.amount
    assert_equal "New transaction created successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
    assert_redirected_to account_transaction_url(account, Account::Transaction.order(:created_at).last)
  end

  test "expenses are positive" do
    assert_difference("Account::Transaction.count") do
      post transactions_url, params: {
        transaction: {
          nature: "expense",
          account_id: @transaction.account_id,
          amount: @transaction.amount,
          currency: @transaction.currency,
          date: @transaction.date,
          name: @transaction.name
        }
      }
    end

    created_transaction = Account::Transaction.order(created_at: :desc).first

    assert_redirected_to account_transaction_url(@transaction.account, created_transaction)
    assert created_transaction.amount.positive?, "Amount should be positive"
  end

  test "incomes are negative" do
    assert_difference("Account::Transaction.count") do
      post transactions_url, params: {
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

    created_transaction = Account::Transaction.order(created_at: :desc).first

    assert_redirected_to account_transaction_url(@transaction.account, created_transaction)
    assert created_transaction.amount.negative?, "Amount should be negative"
  end

  test "should get paginated index with most recent transactions first" do
    get transactions_url
    assert_response :success

    @recent_transactions.first(10).each do |transaction|
      assert_dom "#" + dom_id(transaction), count: 1
    end
  end

  test "transaction count represents filtered total" do
    get transactions_url
    assert_dom "#total-transactions", count: 1, text: @user.family.transactions.select { |t| t.currency == "USD" }.count.to_s

    new_transaction = @user.family.accounts.first.transactions.create! \
      name: "Transaction to search for",
      date: Date.current,
      amount: 0

    get transactions_url(q: { search: new_transaction.name })

    # Only finds 1 transaction that matches filter
    assert_dom "#" + dom_id(new_transaction), count: 1
    assert_dom "#total-transactions", count: 1, text: "1"
  end

  test "can navigate to paginated result" do
    get transactions_url(page: 2)
    assert_response :success

    @recent_transactions[10, 10].select { |t| t.transfer_id == nil }.each do |transaction|
      assert_dom "#" + dom_id(transaction), count: 1
    end
  end

  test "loads last page when page is out of range" do
    user_oldest_transaction = @user.family.transactions.ordered.reject(&:transfer?).last
    get transactions_url(page: 9999999999)

    assert_response :success
    assert_dom "#" + dom_id(user_oldest_transaction), count: 1
  end

  test "can destroy many transactions at once" do
    delete_count = 10
    assert_difference("Account::Transaction.count", -delete_count) do
      post bulk_delete_transactions_url, params: {
        bulk_delete: {
          transaction_ids: @recent_transactions.first(delete_count).pluck(:id)
        }
      }
    end

    assert_redirected_to transactions_url
    assert_equal "10 transactions deleted", flash[:notice]
  end

  test "can update many transactions at once" do
    transactions = @user.family.transactions.ordered.limit(20)

    transactions.each do |transaction|
      transaction.update! \
        excluded: false,
        category_id: Category.first.id,
        merchant_id: Merchant.first.id,
        notes: "Starting note"
    end

    post bulk_update_transactions_url, params: {
      bulk_update: {
        date: Date.current,
        transaction_ids: transactions.map(&:id),
        excluded: true,
        category_id: Category.second.id,
        merchant_id: Merchant.second.id,
        notes: "Updated note"
      }
    }

    assert_redirected_to transactions_url
    assert_equal "#{transactions.count} transactions updated", flash[:notice]

    transactions.reload.each do |transaction|
      assert_equal Date.current, transaction.date
      assert transaction.excluded
      assert_equal Category.second, transaction.category
      assert_equal Merchant.second, transaction.merchant
      assert_equal "Updated note", transaction.notes
    end
  end
end
