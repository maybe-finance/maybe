require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    visit root_url
    open_new_account_modal
  end

  test "can create depository account" do
    assert_account_created("Depository")
  end

  test "can create investment account" do
    assert_account_created("Investment")
  end

  test "can create crypto account" do
    assert_account_created("Crypto")
  end

  test "can create property account" do
    assert_account_created("Property")
  end

  test "can create vehicle account" do
    assert_account_created("Vehicle")
  end

  test "can create other asset account" do
    assert_account_created("OtherAsset")
  end

  test "can create credit card account" do
    assert_account_created("CreditCard")
  end

  test "can create loan account" do
    assert_account_created("Loan")
  end

  test "can create other liability account" do
    assert_account_created("OtherLiability")
  end

  private

    def open_new_account_modal
      click_link "sidebar-new-account"
    end

    def assert_account_created(accountable_type)
      click_link humanized_accountable(accountable_type)
      click_link "Enter account balance manually"

      account_name = "[system test] #{accountable_type} Account"

      fill_in "Account name", with: account_name
      select "Chase", from: "Financial institution"
      fill_in "account[balance]", with: 100.99
      check "Add a start balance for this account"
      fill_in "Start date (optional)", with: 10.days.ago.to_date
      fill_in "Start balance (optional)", with: 95
      click_button "Add #{humanized_accountable(accountable_type).downcase}"

      find("details", text: humanized_accountable(accountable_type)).click
      assert_text account_name

      visit accounts_url
      assert_text account_name
    end

    def humanized_accountable(accountable_type)
      accountable_type.constantize.model_name.human
    end
end
