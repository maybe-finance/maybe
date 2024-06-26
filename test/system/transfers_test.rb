require "application_system_test_case"

class TransfersTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)
    visit transactions_url
  end

  test "can create a transfer" do
    checking_name = accounts(:checking).name
    savings_name = accounts(:savings).name
    transfer_date = Date.current

    click_on "New transaction"

    # Will navigate to different route in same modal
    click_on "Transfer"
    assert_text "New transfer"

    fill_in "Description", with: "Transfer txn name"
    select checking_name, from: "From"
    select savings_name, from: "To"
    fill_in "account_transfer[amount]", with: 500
    fill_in "Date", with: transfer_date
    click_button "Create transfer"

    within "#date-group-" + transfer_date.to_s do
      transfer_name = "Transfer from #{checking_name} to #{savings_name}"
      find("details", text: transfer_name).click
      assert_text "Transfer txn name", count: 2
    end
  end

  test "can match 2 transactions and create a transfer" do
    transfer_date = Date.current
    outflow = Account::Transaction.create! \
      entry: accounts(:savings).entries.build(name: "Outflow from savings account", date: transfer_date, amount: 100, currency: "USD")
    inflow = Account::Transaction.create! \
      entry: accounts(:checking).entries.build(name: "Inflow to checking account", date: transfer_date, amount: -100, currency: "USD")

    visit transactions_url

    transaction_checkbox(inflow).check
    transaction_checkbox(outflow).check

    bulk_transfer_action_button.click

    click_on "Mark as transfers"

    within "#date-group-" + transfer_date.to_s do
      transfer_name = "Transfer from #{outflow.entry.account.name} to #{inflow.entry.account.name}"
      find("details", text: transfer_name).click
      assert_text inflow.entry.name
      assert_text outflow.entry.name
    end
  end

  test "can mark a single transaction as a transfer" do
    txn = @user.family.transactions.ordered_with_entry.first

    within "#" + dom_id(txn) do
      assert_text "Uncategorized"
    end

    transaction_checkbox(txn).check

    bulk_transfer_action_button.click
    click_on "Mark as transfers"

    within "#" + dom_id(txn) do
      assert_no_text "Uncategorized"
    end
  end

  private

    def transaction_checkbox(transaction)
      find("#" + dom_id(transaction, "selection"))
    end

    def bulk_transfer_action_button
      find("#bulk-transfer-btn")
    end
end
