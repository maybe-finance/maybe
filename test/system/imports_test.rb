require "application_system_test_case"

class ImportsTest < ApplicationSystemTestCase
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)

    @imports = @user.family.imports.ordered.to_a
  end

  test "can trigger new import from settings" do
    trigger_import_from_settings
    verify_import_modal
  end

  test "can resume existing import from settings" do
    visit imports_url

    within "#" + dom_id(@imports.first) do
      click_button
      click_link "Edit"
    end

    assert_current_path edit_import_path(@imports.first)
  end

  test "can resume latest import" do
    trigger_import_from_transactions
    verify_import_modal

    click_link "Resume latest import"

    assert_current_path edit_import_path(@imports.first)
  end

  test "can perform basic CSV import" do
    trigger_import_from_settings
    verify_import_modal

    within "#modal" do
      click_link "New import from CSV"
    end

    # 1) Create import step
    assert_selector "h1", text: "New import"

    within "form" do
      select "Checking Account", from: "import_account_id"
    end

    click_button "Next"

    # 2) Load Step
    assert_selector "h1", text: "Load import"

    within "form" do
      fill_in "import_raw_csv_str", with: <<-ROWS
        date,Custom Name Column,category,amount
        invalid_date,Starbucks drink,Food,-20.50
        2024-01-01,Amazon purchase,Shopping,-89.50
      ROWS
    end

    click_button "Next"

    # 3) Configure step
    assert_selector "h1", text: "Configure import"

    within "form" do
      select "Custom Name Column", from: "import_column_mappings_name"
    end

    click_button "Next"

    # 4) Clean step
    assert_selector "h1", text: "Clean import"

    # We have an invalid value, so user cannot click next yet
    assert_no_text "Next"

    # Replace invalid date with valid date
    fill_in "cell-0-0", with: "2024-01-02"

    # Trigger blur event so value saves
    find("body").click

    click_link "Next"

    # 5) Confirm step
    assert_selector "h1", text: "Confirm import"
    click_button "Import 2 transactions"
    assert_selector "h1", text: "Imports"
  end

  private

    def trigger_import_from_settings
      visit imports_url
      click_link "New import"
    end

    def trigger_import_from_transactions
      visit transactions_url
      click_link "Import"
    end

    def verify_import_modal
      within "#modal" do
        assert_text "Import transactions"
      end
    end
end
