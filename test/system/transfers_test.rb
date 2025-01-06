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

    select checking_name, from: "From"
    select savings_name, from: "To"
    fill_in "transfer[amount]", with: 500
    fill_in "Date", with: transfer_date

    click_button "Create transfer"

    within "#entry-group-" + transfer_date.to_s do
      assert_text "Payment to"
    end
  end
end
