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
    tooltip_element = find('[data-controller="tooltip"]')
    tooltip_element.hover
    tooltip_contents = find('[data-tooltip-target="tooltip"]')
    assert tooltip_contents.visible?
    within tooltip_contents do
      assert_text I18n.t("accounts.tooltip.total_value_tooltip")
      assert_text I18n.t("accounts.tooltip.holdings")
      assert_text format_money(@account.investment.holdings_value, precision: 0)
      assert_text I18n.t("accounts.tooltip.cash")
      assert_text format_money(@account.balance_money, precision: 0)
    end
    find("body").click
    assert find('[data-tooltip-target="tooltip"]', visible: false)
  end
end
