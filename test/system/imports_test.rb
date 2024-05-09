require "application_system_test_case"

class ImportsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    @imports = @user.family.imports
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

  test "can perform basic CSV import" do
    trigger_import_from_transactions
    verify_import_modal

    within "#modal" do
      click_link "Import from CSV"
    end

    assert_selector "h1", text: "New import"

    within "form" do
      select "Checking Account", from: "import_account_id"
    end

    click_button "Next"

    assert_selector "h1", text: "Load import"
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
