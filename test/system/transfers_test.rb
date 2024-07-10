require "application_system_test_case"

class TransfersTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)
    visit transactions_url
  end

  test "can create a transfer" do
    checking_name = accounts(:depository).name
    savings_name = accounts(:credit_card).name
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

    within "#entry-group-" + transfer_date.to_s do
      assert_text "Transfer from"
    end
  end

  test "can match 2 transactions and create a transfer" do
    transfer_date = Date.current
    outflow = accounts(:depository).entries.create! \
      name: "Outflow from checking account",
      date: transfer_date,
      amount: 100,
      currency: "USD",
      entryable: Account::Transaction.new

    inflow = accounts(:credit_card).entries.create! \
      name: "Inflow to cc account",
      date: transfer_date,
      amount: -100,
      currency: "USD",
      entryable: Account::Transaction.new

    visit transactions_url

    transaction_entry_checkbox(inflow).check
    transaction_entry_checkbox(outflow).check

    bulk_transfer_action_button.click

    click_on "Mark as transfers"

    within "#entry-group-" + transfer_date.to_s do
      assert_text "Transfer from"
    end
  end

  test "can mark a single transaction as a transfer" do
    txn = @user.family.entries.reverse_chronological.first

    within "#" + dom_id(txn) do
      assert_text txn.account_transaction.category.name || "Uncategorized"
    end

    transaction_entry_checkbox(txn).check

    bulk_transfer_action_button.click
    click_on "Mark as transfers"

    within "#" + dom_id(txn) do
      assert_no_text "Uncategorized"
    end
  end

  private

    def transaction_entry_checkbox(transaction_entry)
      find("#" + dom_id(transaction_entry, "selection"))
    end

    def bulk_transfer_action_button
      find("#bulk-transfer-btn")
    end
end
