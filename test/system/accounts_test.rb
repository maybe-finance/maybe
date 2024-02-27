require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)
  end

  test "should create account" do
    skip("Disabling this test for now, UI is changing to quickly to do systems testing")

    click_on "New account"
    click_on "Credit Card"
    within "form" do
      fill_in "Name", with: "VISA"
      fill_in "Balance", with: "1000"
      click_on "Submit"
    end
    assert_text "$1,000"
  end
end
