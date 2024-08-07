require "application_system_test_case"

class TradesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sign_in @user = users(:family_admin)

    @account = accounts(:investment)

    visit_account_trades
  end

  test "can create buy transaction" do
    shares_qty = 25.0

    open_new_trade_modal

    fill_in "Holding", with: "NVDA"
    fill_in "Date", with: Date.current
    fill_in "Quantity", with: shares_qty
    fill_in "account_entry[entryable_attributes][price]", with: 214.23

    click_button "Add transaction"

    visit_account_trades

    within_trades do
      assert_text "Purchase 10 shares of AAPL"
      assert_text "Buy #{shares_qty} shares of NVDA"
    end
  end

  test "can create sell transaction" do
    aapl = @account.holdings.current.find { |h| h.security.ticker == "AAPL" }

    open_new_trade_modal

    select "Sell", from: "Type"
    fill_in "Holding", with: aapl.ticker
    fill_in "Date", with: Date.current
    fill_in "Quantity", with: aapl.qty
    fill_in "account_entry[entryable_attributes][price]", with: 215.33

    click_button "Add transaction"

    visit_account_trades

    within_trades do
      assert_text "Sell #{aapl.qty} shares of AAPL"
    end
  end

  private

    def open_new_trade_modal
      click_link "new_trade_account_#{@account.id}"
    end

    def within_trades(&block)
      within "#" + dom_id(@account, "trades"), &block
    end

    def visit_account_trades
      visit account_url(@account, tab: "trades")
    end
end
