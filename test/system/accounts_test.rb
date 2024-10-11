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
    assert_account_created "Property" do
      fill_in "Year built", with: 2005
      fill_in "Area value", with: 2250
      fill_in "Address line 1", with: "123 Main St"
      fill_in "Address line 2", with: "Apt 4B"
      fill_in "City", with: "San Francisco"
      fill_in "State", with: "CA"
      fill_in "Postal code", with: "94101"
      fill_in "Country", with: "US"
    end
  end

  test "can create vehicle account" do
    assert_account_created "Vehicle" do
      fill_in "Make", with: "Toyota"
      fill_in "Model", with: "Camry"
      fill_in "Year", with: "2020"
      fill_in "Mileage", with: "30000"
    end
  end

  test "can create other asset account" do
    assert_account_created("OtherAsset")
  end

  test "can create credit card account" do
    assert_account_created "CreditCard" do
      fill_in "Available credit", with: 1000
      fill_in "Minimum payment", with: 25
      fill_in "APR", with: 15.25
      fill_in "Expiration date", with: 1.year.from_now.to_date
      fill_in "Annual fee", with: 100
    end
  end

  test "can create loan account" do
    assert_account_created "Loan" do
      fill_in "Interest rate", with: 5.25
      select "Fixed", from: "Rate type"
      fill_in "Term (months)", with: 360
    end
  end

  test "can create other liability account" do
    assert_account_created("OtherLiability")
  end

  test "can sync all acounts on accounts page" do
    visit accounts_url
    assert_button "Sync all"
  end

  private

    def open_new_account_modal
      click_link "sidebar-new-account"
    end

    def assert_account_created(accountable_type, &block)
      click_link humanized_accountable(accountable_type)
      click_link "Enter account balance manually"

      account_name = "[system test] #{accountable_type} Account"

      fill_in "Account name", with: account_name
      fill_in "account[balance]", with: 100.99
      fill_in "Start date (optional)", with: 10.days.ago.to_date
      fill_in "account[start_balance]", with: 95.25

      yield if block_given?

      click_button "Add #{humanized_accountable(accountable_type).downcase}"

      find("details", text: humanized_accountable(accountable_type)).click
      assert_text account_name

      visit accounts_url
      assert_text account_name

      visit account_url(Account.order(:created_at).last)

      within "header" do
        find('button[data-menu-target="button"]').click
        click_on "Edit"
      end

      fill_in "Account name", with: "Updated account name"
      click_button "Update #{humanized_accountable(accountable_type).downcase}"
      assert_selector "h2", text: "Updated account name"
    end

    def humanized_accountable(accountable_type)
      accountable_type.constantize.model_name.human
    end
end
