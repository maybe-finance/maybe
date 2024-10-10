require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  include Account::EntriesTestHelper

  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_entries(:transaction)
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
    entry_params = {
      account_id: account.id,
      amount: 100.45,
      currency: "USD",
      date: Date.current,
      name: "Test transaction",
      entryable_type: "Account::Transaction",
      entryable_attributes: { category_id: categories(:food_and_drink).id }
    }

    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], 1 do
      post transactions_url, params: { account_entry: entry_params }
    end

    assert_equal entry_params[:amount].to_d, Account::Transaction.order(created_at: :desc).first.entry.amount
    assert_equal "New transaction created successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
    assert_redirected_to account_url(account)
  end

  test "expenses are positive" do
    assert_difference([ "Account::Transaction.count", "Account::Entry.count" ], 1) do
      post transactions_url, params: {
        account_entry: {
          nature: "expense",
          account_id: @transaction.account_id,
          amount: @transaction.amount,
          currency: @transaction.currency,
          date: @transaction.date,
          name: @transaction.name,
          entryable_type: "Account::Transaction",
          entryable_attributes: {}
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert_redirected_to account_url(@transaction.account)
    assert created_entry.amount.positive?, "Amount should be positive"
  end

  test "incomes are negative" do
    assert_difference("Account::Transaction.count") do
      post transactions_url, params: {
        account_entry: {
          nature: "income",
          account_id: @transaction.account_id,
          amount: @transaction.amount,
          currency: @transaction.currency,
          date: @transaction.date,
          name: @transaction.name,
          entryable_type: "Account::Transaction",
          entryable_attributes: { category_id: categories(:food_and_drink).id }
        }
      }
    end

    created_entry = Account::Entry.order(created_at: :desc).first

    assert_redirected_to account_url(@transaction.account)
    assert created_entry.amount.negative?, "Amount should be negative"
  end

  test "transaction count represents filtered total" do
    family = families(:empty)
    sign_in family.users.first
    account = family.accounts.create! name: "Test", balance: 0, currency: "USD", accountable: Depository.new

    3.times do
      create_transaction(account: account)
    end

    get transactions_url(per_page: 10)

    assert_dom "#total-transactions", count: 1, text: family.entries.account_transactions.size.to_s

    searchable_transaction = create_transaction(account: account, name: "Unique test name")

    get transactions_url(q: { search: searchable_transaction.name })

    # Only finds 1 transaction that matches filter
    assert_dom "#" + dom_id(searchable_transaction), count: 1
    assert_dom "#total-transactions", count: 1, text: "1"
  end

  test "can paginate" do
    family = families(:empty)
    sign_in family.users.first
    account = family.accounts.create! name: "Test", balance: 0, currency: "USD", accountable: Depository.new

    11.times do
      create_transaction(account: account)
    end

    sorted_transactions = family.entries.account_transactions.reverse_chronological.to_a

    assert_equal 11, sorted_transactions.count

    get transactions_url(page: 1, per_page: 10)

    assert_response :success
    sorted_transactions.first(10).each do |transaction|
      assert_dom "#" + dom_id(transaction), count: 1
    end

    get transactions_url(page: 2, per_page: 10)

    assert_dom "#" + dom_id(sorted_transactions.last), count: 1

    get transactions_url(page: 9999999, per_page: 10) # out of range loads last page

    assert_dom "#" + dom_id(sorted_transactions.last), count: 1
  end

  test "can destroy many transactions at once" do
    transactions = @user.family.entries.account_transactions
    delete_count = transactions.size

    assert_difference([ "Account::Transaction.count", "Account::Entry.count" ], -delete_count) do
      post bulk_delete_transactions_url, params: {
        bulk_delete: {
          entry_ids: transactions.pluck(:id)
        }
      }
    end

    assert_redirected_to transactions_url
    assert_equal "#{delete_count} transactions deleted", flash[:notice]
  end

  test "can update many transactions at once" do
    transactions = @user.family.entries.account_transactions

    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], 0 do
      post bulk_update_transactions_url, params: {
        bulk_update: {
          entry_ids: transactions.map(&:id),
          date: 1.day.ago.to_date,
          category_id: Category.second.id,
          merchant_id: Merchant.second.id,
          notes: "Updated note"
        }
      }
    end

    assert_redirected_to transactions_url
    assert_equal "#{transactions.count} transactions updated", flash[:notice]

    transactions.reload.each do |transaction|
      assert_equal 1.day.ago.to_date, transaction.date
      assert_equal Category.second, transaction.account_transaction.category
      assert_equal Merchant.second, transaction.account_transaction.merchant
      assert_equal "Updated note", transaction.notes
    end
  end
end
