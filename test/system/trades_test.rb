require "application_system_test_case"

class TradesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sign_in @user = users(:family_admin)

    @account = accounts(:investment)

    visit_account_portfolio

    # Disable provider to focus on form testing
    Security.stubs(:provider).returns(nil)
  end

  test "can create buy transaction" do
    shares_qty = 25

    open_new_trade_modal

    fill_in "Ticker symbol", with: "AAPL"
    fill_in "Date", with: Date.current
    fill_in "Quantity", with: shares_qty
    fill_in "entry[price]", with: 214.23

    click_button "Add transaction"

    visit_trades

    within_trades do
      assert_text "Buy #{shares_qty} shares of AAPL"
    end
  end

  test "can create sell transaction" do
    qty = 10
    aapl = @account.holdings.find { |h| h.security.ticker == "AAPL" }

    open_new_trade_modal

    select "Sell", from: "Type"
    fill_in "Ticker symbol", with: aapl.ticker
    fill_in "Date", with: Date.current
    fill_in "Quantity", with: qty
    fill_in "entry[price]", with: 215.33

    click_button "Add transaction"

    visit_trades

    within_trades do
      assert_text "Sell #{qty} shares of AAPL"
    end
  end

  private
    def open_new_trade_modal
      click_on "New transaction"
    end

    def within_trades(&block)
      within "#" + dom_id(@account, "entries"), &block
    end

    def visit_trades
      visit account_path(@account, tab: "activity")
    end

    def visit_account_portfolio
      visit account_path(@account, tab: "holdings")
    end
end
