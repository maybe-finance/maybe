require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    @latest_transactions = @user.family.transactions.ordered.limit(20).to_a
    @test_category = @user.family.transaction_categories.create! name: "System Test Category"
    @test_merchant = @user.family.transaction_merchants.create! name: "System Test Merchant"
    @target_txn = @user.family.accounts.first.transactions.create! \
      name: "Oldest transaction",
      date: 10.years.ago.to_date,
      category: @test_category,
      merchant: @test_merchant,
      amount: 100

    visit transactions_url
  end

  test "can search for a transaction" do
    assert_selector "h1", text: "Transactions"

    within "form#transactions-search" do
      fill_in "Search transactions by name", with: @target_txn.name
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

  test "all filters work and empty state shows if no match" do
    find("#transaction-filters-button").click

    within "#transaction-filters-menu" do
      click_button "Account"
      check(@target_txn.account.name)

      click_button "Date"
      fill_in "q_start_date", with: 10.days.ago.to_date
      fill_in "q_end_date", with: Date.current

      click_button "Type"
      assert_text "Filter by type coming soon..."

      click_button "Amount"
      assert_text "Filter by amount coming soon..."

      click_button "Category"
      check(@test_category.name)

      click_button "Merchant"
      check(@test_merchant.name)

      click_button "Apply"
    end

    assert_text "No transactions found"

    # Page reload doesn't affect results
    visit current_url

    assert_text "No transactions found"

    within "ul#transaction-search-filters" do
      find("li", text: @target_txn.account.name).first("a").click
      find("li", text: "on or after #{10.days.ago.to_date}").first("a").click
      find("li", text: "on or before #{Date.current}").first("a").click
      find("li", text: @target_txn.category.name).first("a").click
      find("li", text: @target_txn.merchant.name).first("a").click
    end

    assert_selector "#" + dom_id(@user.family.transactions.ordered.first), count: 1
  end

  test "can select and deselect one or more transactions" do
    check_transaction_selection(@latest_transactions.first)
    assert_selection_count(1)
    check_transaction_selection(@latest_transactions.second)
    assert_selection_count(2)
    uncheck_transaction_selection(@latest_transactions.first)
    assert_selection_count(1)
  end

  private

    def assert_selection_count(count)
      within "#transaction-selection-bar" do
        assert_text "#{count} transaction#{count == 1 ? "" : "s"} selected"
      end
    end

    def check_transaction_selection(transaction)
      within "#" + dom_id(transaction, "selection_form") do
        find("input[type='checkbox']").check

        assert_checked_field
      end
    end

    def uncheck_transaction_selection(transaction)
      within "#" + dom_id(transaction, "selection_form") do
        find("input[type='checkbox']").uncheck

        refute_checked_field
      end
    end
end
