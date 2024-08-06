require "application_system_test_case"

class TradesTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    @account = accounts(:investment)

    visit account_url(@account)
  end

  test "can create depository account" do
    open_new_trade_modal
  end

  private

    def open_new_trade_modal
      click_link "new_trade_account_#{@account.id}"
    end
end
