require "application_system_test_case"

class TooltipsTest < ApplicationSystemTestCase
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:investment)
  end

  test "can see account information tooltip" do
    visit account_path(@account)
    find('[data-controller="tooltip"]').hover
    assert_selector("#tooltip[data-show]", visible: true)
    within "#tooltip" do
      assert_text I18n.t("accounts.tooltip.total_value_tooltip")
      assert_text I18n.t("accounts.tooltip.holdings")
      assert_text format_money(@account.investment.holdings_value, precision: 0)
      assert_text I18n.t("accounts.tooltip.cash")
      assert_text format_money(@account.balance_money, precision: 0)
    end
    find("body").click
    assert_no_selector("#tooltip[data-show]", visible: true)
  end
end
