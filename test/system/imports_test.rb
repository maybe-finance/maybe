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

    assert_selector "h1", text: "New import"

    within "form" do
      select "Checking Account", from: "import_account_id"
    end

    click_button "Next"
    assert_selector "h1", text: "Load import"

    within "form" do
      fill_in "import_raw_csv", with: valid_csv_str
    end

    click_button "Next"
    assert_selector "h1", text: "Configure import"

    # If raw CSV already has correct columns, no need to edit the mappings
    click_button "Next"
    assert_selector "h1", text: "Clean import"

    # For part 1 of this implementation, user cannot "clean" their data inline, so data is assumed to be cleaned at this point
    click_link "Next"
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
