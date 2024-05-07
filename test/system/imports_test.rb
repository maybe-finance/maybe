require "application_system_test_case"

class ImportsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)
  end

  test "can trigger new import from settings" do
    trigger_import_from_settings
    verify_import_modal
  end

  test "can perform basic CSV import" do
    trigger_import_from_transactions
    verify_import_modal

    within "#modal" do
      click_link "Import from CSV"
    end

    assert_selector "h1", text: "New import"
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
