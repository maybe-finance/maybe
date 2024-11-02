require "application_system_test_case"

class TradesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sign_in @user = users(:family_admin)

    @account = accounts(:investment)

    visit_account_trades

    Security::SynthComboboxOption.stubs(:find_in_synth).returns([
      Security::SynthComboboxOption.new(
        symbol: "AAPL",
        name: "Apple Inc.",
        logo_url: "https://logo.synthfinance.com/ticker/AAPL",
        exchange_acronym: "NASDAQ",
        exchange_mic: "XNAS"
      )
    ])
  end

  test "can create buy transaction" do
    shares_qty = 25.0

    open_new_trade_modal

    fill_in "Ticker symbol", with: "AAPL"
    select_combobox_option("Apple")
    fill_in "Date", with: Date.current
    fill_in "Quantity", with: shares_qty
    fill_in "account_entry[price]", with: 214.23

    click_button "Add transaction"

    visit_account_trades

    within_trades do
      assert_text "Purchase 10 shares of AAPL"
      assert_text "Buy #{shares_qty} shares of AAPL"
    end
  end

  test "can create sell transaction" do
    aapl = @account.holdings.current.find { |h| h.security.ticker == "AAPL" }

    open_new_trade_modal

    select "Sell", from: "Type"
    fill_in "Ticker symbol", with: aapl.ticker
    select_combobox_option(aapl.security.name)
    fill_in "Date", with: Date.current
    fill_in "Quantity", with: aapl.qty
    fill_in "account_entry[price]", with: 215.33

    click_button "Add transaction"

    visit_account_trades

    within_trades do
      assert_text "Sell #{aapl.qty} shares of AAPL"
    end
  end

  private

    def open_new_trade_modal
      click_on "New"
      click_on "New transaction"
    end

    def within_trades(&block)
      within "#" + dom_id(@account, "entries"), &block
    end

    def visit_account_trades
      visit polymorphic_path(@account.accountable)
    end

    def select_combobox_option(text)
      within "#account_entry_ticker-hw-listbox" do
        find("li", text: text).click
      end
    end
end
