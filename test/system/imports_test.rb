require "application_system_test_case"

class ImportsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sign_in @user = users(:family_admin)

    # Trade securities will be imported as "offline" tickers
    Security.stubs(:provider).returns(nil)
  end

  test "transaction import" do
    visit new_import_path

    click_on "Import transactions"

    fill_in "import[raw_file_str]", with: file_fixture("imports/transactions.csv").read

    find('input[type="submit"][value="Upload CSV"]').click

    select "Date", from: "Date*"
    select "YYYY-MM-DD", from: "Date format"
    select "Amount", from: "Amount"
    select "Account", from: "Account (optional)"
    select "Name", from: "Name (optional)"
    select "Category", from: "Category (optional)"
    select "Tags", from: "Tags (optional)"
    select "Notes", from: "Notes (optional)"

    click_on "Apply configuration"

    click_on "Next step"

    assert_selector "h1", text: "Assign your categories"
    click_on "Next"

    assert_selector "h1", text: "Assign your tags"
    click_on "Next"

    assert_selector "h1", text: "Assign your accounts"
    click_on "Next"

    click_on "Publish import"

    assert_text "Import in progress"

    perform_enqueued_jobs

    click_on "Check status"

    assert_text "Import successful"

    click_on "Back to dashboard"
  end

  test "trade import" do
    visit new_import_path

    click_on "Import investments"

    fill_in "import[raw_file_str]", with: file_fixture("imports/trades.csv").read

    find('input[type="submit"][value="Upload CSV"]').click

    select "YYYY-MM-DD", from: "Date format"

    click_on "Apply configuration"

    click_on "Next step"

    assert_selector "h1", text: "Assign your accounts"
    click_on "Next"

    click_on "Publish import"

    assert_text "Import in progress"

    perform_enqueued_jobs

    click_on "Check status"

    assert_text "Import successful"

    click_on "Back to dashboard"
  end

  test "account import" do
    visit new_import_path

    click_on "Import accounts"

    fill_in "import[raw_file_str]", with: file_fixture("imports/accounts.csv").read

    find('input[type="submit"][value="Upload CSV"]').click

    click_on "Apply configuration"

    click_on "Next step"

    assert_selector "h1", text: "Assign your account types"

    all("form").each do |form|
      within(form) do
        select = form.find("select")
        select "Depository", from: select["id"]
        sleep 0.5
      end
    end

    click_on "Next"

    click_on "Publish import"

    assert_text "Import in progress"

    perform_enqueued_jobs

    click_on "Check status"

    assert_text "Import successful"

    click_on "Back to dashboard"
  end

  test "mint import" do
    visit new_import_path

    click_on "Import from Mint"

    fill_in "import[raw_file_str]", with: file_fixture("imports/mint.csv").read

    find('input[type="submit"][value="Upload CSV"]').click

    click_on "Apply configuration"

    click_on "Next step"

    assert_selector "h1", text: "Assign your categories"
    click_on "Next"

    assert_selector "h1", text: "Assign your tags"
    click_on "Next"

    assert_selector "h1", text: "Assign your accounts"
    click_on "Next"

    click_on "Publish import"

    assert_text "Import in progress"

    perform_enqueued_jobs

    click_on "Check status"

    assert_text "Import successful"

    click_on "Back to dashboard"
  end
end
