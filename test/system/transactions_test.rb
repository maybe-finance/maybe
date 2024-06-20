require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    @latest_transactions = @user.family.transactions.ordered.limit(20).to_a
    @test_category = @user.family.categories.create! name: "System Test Category"
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

  test "can select and deselect entire page of transactions" do
    all_transactions_checkbox.check
    assert_selection_count(number_of_transactions_on_page)
    all_transactions_checkbox.uncheck
    assert_selection_count(0)
  end

  test "can select and deselect groups of transactions" do
    date_transactions_checkbox(12.days.ago.to_date).check
    assert_selection_count(3)
    date_transactions_checkbox(12.days.ago.to_date).uncheck
    assert_selection_count(0)
  end

  test "can select and deselect individual transactions" do
    transaction_checkbox(@latest_transactions.first).check
    assert_selection_count(1)
    transaction_checkbox(@latest_transactions.second).check
    assert_selection_count(2)
    transaction_checkbox(@latest_transactions.second).uncheck
    assert_selection_count(1)
  end

  test "outermost group always overrides inner selections" do
    transaction_checkbox(@latest_transactions.first).check
    assert_selection_count(1)
    all_transactions_checkbox.check
    assert_selection_count(number_of_transactions_on_page)
    transaction_checkbox(@latest_transactions.first).uncheck
    assert_selection_count(number_of_transactions_on_page - 1)
    date_transactions_checkbox(12.days.ago.to_date).uncheck
    assert_selection_count(number_of_transactions_on_page - 4)
    all_transactions_checkbox.uncheck
    assert_selection_count(0)
  end

  private

    def number_of_transactions_on_page
      page_size = 50

      [ @user.family.transactions.where(transfer_id: nil).count, page_size ].min
    end

    def all_transactions_checkbox
      find("#selection_transaction")
    end

    def date_transactions_checkbox(date)
      find("#selection_transaction_#{date}")
    end

    def transaction_checkbox(transaction)
      find("#" + dom_id(transaction, "selection"))
    end

    def assert_selection_count(count)
      if count == 0
        assert_no_selector("#transaction-selection-bar")
      else
        within "#transaction-selection-bar" do
          assert_text "#{count} transaction#{count == 1 ? "" : "s"} selected"
        end
      end
    end
end
