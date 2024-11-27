require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  include Account::EntriesTestHelper

  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_entries(:transaction)
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
end
