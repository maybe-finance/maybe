require "test_helper"

class Account::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_transactions(:checking_one)
    @recent_transactions = @user.family.transactions.ordered.limit(20).to_a
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
      post bulk_delete_account_transactions_url, params: { bulk_delete: { transaction_ids: @recent_transactions.first(delete_count).pluck(:id) } }
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

    post bulk_update_account_transactions_url, params: {
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
