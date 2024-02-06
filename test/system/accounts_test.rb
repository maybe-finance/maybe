require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:bob)
  end

  test "should create account" do
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
