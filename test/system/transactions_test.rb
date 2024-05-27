require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    @test_category = @user.family.transaction_categories.create! name: "System Test Category"
    @target_txn = @user.family.accounts.first.transactions.create! \
      name: "Oldest transaction",
      date: 10.years.ago.to_date,
      category: @test_category,
      amount: 100

    visit transactions_url
  end

  test "can search for a transaction" do
    assert_selector "h1", text: "Transactions"

    within "form#transaction_search" do
      fill_in "Search transaction by name, merchant, category or amount", with: @target_txn.name
    end

    assert_selector "#" + dom_id(@target_txn), count: 1

    within "#transaction-search-filters" do
      assert_text @target_txn.name
    end
  end

  test "can open filters and apply one or more" do
    find("#transaction-filters-button").click

    within "#transaction-filters-menu" do
      check(@target_txn.account.name)
      click_button "Category"
      check(@test_category.name)
      click_button "Apply"
    end

    assert_selector "#" + dom_id(@target_txn), count: 1

    within "#transaction-search-filters" do
      assert_text @target_txn.account.name
      assert_text @target_txn.category.name
    end
  end
end
