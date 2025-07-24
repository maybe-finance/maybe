require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    Entry.delete_all # clean slate

    create_transaction("one", 12.days.ago.to_date, 100)
    create_transaction("two", 10.days.ago.to_date, 100)
    create_transaction("three", 9.days.ago.to_date, 100)
    create_transaction("four", 8.days.ago.to_date, 100)
    create_transaction("five", 7.days.ago.to_date, 100)
    create_transaction("six", 7.days.ago.to_date, 100)
    create_transaction("seven", 4.days.ago.to_date, 100)
    create_transaction("eight", 3.days.ago.to_date, 100)
    create_transaction("nine", 1.days.ago.to_date, 100)
    @uncategorized_transaction = create_transaction("ten", 1.days.ago.to_date, 100)
    create_transaction("eleven", Date.current, 100, category: categories(:food_and_drink), tags: [ tags(:one) ], merchant: merchants(:amazon))

    @transactions = @user.family.entries
                         .transactions
                         .reverse_chronological

    @transaction = @transactions.first

    @page_size = 10

    visit transactions_url(per_page: @page_size)
  end

  test "can search for a transaction" do
    assert_selector "h1", text: "Transactions"

    within "form#transactions-search" do
      fill_in "Search transactions ...", with: @transaction.name
      find("#q_search").send_keys(:tab) # Trigger blur to submit form
    end

    assert_selector "#" + dom_id(@transaction), count: 1

    within "#transaction-search-filters" do
      assert_text @transaction.name
    end
  end

  test "can open filters and apply one or more" do
    find("#transaction-filters-button").click

    within "#transaction-filters-menu" do
      check(@transaction.account.name)
      click_button "Category"
      check(@transaction.transaction.category.name)
      click_button "Apply"
    end

    assert_selector "#" + dom_id(@transaction), count: 1

    within "#transaction-search-filters" do
      assert_text @transaction.account.name
      assert_text @transaction.transaction.category.name
    end
  end

  test "can filter uncategorized transactions" do
    find("#transaction-filters-button").click

    within "#transaction-filters-menu" do
      click_button "Category"
      check("Uncategorized")
      click_button "Apply"
    end

    assert_selector "#" + dom_id(@uncategorized_transaction), count: 1
    assert_no_selector("#" + dom_id(@transaction))

    find("#transaction-filters-button").click

    within "#transaction-filters-menu" do
      click_button "Category"
      check(@transaction.transaction.category.name)
      click_button "Apply"
    end

    assert_selector "#" + dom_id(@transaction), count: 1
    assert_selector "#" + dom_id(@uncategorized_transaction), count: 1
  end

  test "all filters work and empty state shows if no match" do
    find("#transaction-filters-button").click

    account = @transaction.account
    category = @transaction.transaction.category
    merchant = @transaction.transaction.merchant

    within "#transaction-filters-menu" do
      click_button "Account"
      check(account.name)

      click_button "Date"
      fill_in "q_start_date", with: 10.days.ago.to_date
      fill_in "q_end_date", with: 1.day.ago.to_date

      click_button "Type"
      check("Income")

      click_button "Amount"
      select "Less than"
      fill_in "q_amount", with: 200

      click_button "Category"
      check(category.name)

      click_button "Merchant"
      check(merchant.name)

      click_button "Apply"
    end

    assert_text "No entries found"

    # Wait for Turbo to finish updating the DOM
    sleep 0.5

    # Page reload doesn't affect results
    visit current_url

    assert_text "No entries found"

    # Remove all filters by clicking their X buttons
    # Get all the filter buttons at once to avoid stale elements
    filter_count = page.all("ul#transaction-search-filters li button").count

    # Click each one with a small delay to let Turbo update
    filter_count.times do
      page.all("ul#transaction-search-filters li button").first.click
      sleep 0.1
    end

    assert_text @transaction.name
  end

  test "can select and deselect entire page of transactions" do
    all_transactions_checkbox.check
    assert_selection_count(number_of_transactions_on_page)
    all_transactions_checkbox.uncheck
    assert_selection_count(0)
  end

  test "can select and deselect groups of transactions" do
    date_transactions_checkbox(1.day.ago.to_date).check
    assert_selection_count(2)

    date_transactions_checkbox(1.day.ago.to_date).uncheck
    assert_selection_count(0)
  end

  test "can select and deselect individual transactions" do
    transaction_checkbox(@transactions.first).check
    assert_selection_count(1)
    transaction_checkbox(@transactions.second).check
    assert_selection_count(2)
    transaction_checkbox(@transactions.second).uncheck
    assert_selection_count(1)
  end

  test "outermost group always overrides inner selections" do
    transaction_checkbox(@transactions.first).check
    assert_selection_count(1)

    all_transactions_checkbox.check
    assert_selection_count(number_of_transactions_on_page)

    transaction_checkbox(@transactions.first).uncheck
    assert_selection_count(number_of_transactions_on_page - 1)

    date_transactions_checkbox(1.day.ago.to_date).uncheck
    assert_selection_count(number_of_transactions_on_page - 3)

    all_transactions_checkbox.uncheck
    assert_selection_count(0)
  end


  test "can create deposit transaction for investment account" do
    investment_account = accounts(:investment)
    investment_account.entries.create!(name: "Investment account", date: Date.current, amount: 1000, currency: "USD", entryable: Transaction.new)
    transfer_date = Date.current
    visit account_url(investment_account, tab: "activity")
    within "[data-testid='activity-menu']" do
      click_on "New"
      click_on "New transaction"
    end
    select "Deposit", from: "Type"
    fill_in "Date", with: transfer_date
    fill_in "model[amount]", with: 175.25
    click_button "Add transaction"
    within "#" + dom_id(investment_account, "entries_#{transfer_date}") do
      assert_text "175.25"
    end
  end

  test "transfers should always sum to zero" do
    asset_account = accounts(:other_asset)
    investment_account = accounts(:investment)
    outflow_entry = create_transaction("outflow", Date.current, 500, account: asset_account)
    inflow_entry = create_transaction("inflow", 1.day.ago.to_date, -500, account: investment_account)
    @user.family.auto_match_transfers!
    visit transactions_url

    within "#entry-group-" + Date.current.to_s + "-totals" do
      assert_text "-$100.00" # transaction eleven from setup
    end
  end

  private

    def create_transaction(name, date, amount, category: nil, merchant: nil, tags: [], account: nil)
      account ||= accounts(:depository)

      account.entries.create! \
        name: name,
        date: date,
        amount: amount,
        currency: "USD",
        entryable: Transaction.new(category: category, merchant: merchant, tags: tags)
    end

    def number_of_transactions_on_page
      [ @user.family.entries.count, @page_size ].min
    end

    def all_transactions_checkbox
      find("#selection_entry")
    end

    def date_transactions_checkbox(date)
      find("#selection_entry_#{date}")
    end

    def transaction_checkbox(transaction)
      find("#" + dom_id(transaction, "selection"))
    end

    def assert_selection_count(count)
      if count == 0
        assert_no_selector("#entry-selection-bar")
      else
        within "#entry-selection-bar" do
          assert_text "#{count} transaction#{count == 1 ? "" : "s"} selected"
        end
      end
    end
end
