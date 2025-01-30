require "test_helper"

class AccountListTest < ActionView::TestCase
  test "renders account list without error when trend is nil" do
    account = Account.new(currency: "USD", balance: 100)
    account_value_node = OpenStruct.new(
      name: "Test Account",
      original: account,
      series: OpenStruct.new(trend: nil)
    )
    group = OpenStruct.new(
      name: "Assets",
      children: [account_value_node],
      series: OpenStruct.new(trend: OpenStruct.new(color: "#000", value: 0, percent: 0)),
      sum: 100
    )

    assert_nothing_raised do
      render partial: "accounts/account_list", locals: { group: group }
    end
    
    assert_select "span[style*='color:']", count: 1 # Only group trend should be visible
  end

  test "renders account list with trends when present" do
    account = Account.new(currency: "USD", balance: 100)
    account_value_node = OpenStruct.new(
      name: "Test Account",
      original: account,
      series: OpenStruct.new(
        trend: OpenStruct.new(color: "#00ff00", value: 10, percent: 10)
      )
    )
    group = OpenStruct.new(
      name: "Assets",
      children: [account_value_node],
      series: OpenStruct.new(
        trend: OpenStruct.new(color: "#00ff00", value: 10, percent: 10)
      ),
      sum: 100
    )

    render partial: "accounts/account_list", locals: { group: group }
    
    assert_select "span[style*='color:']", count: 2 # Both group and account trends should be visible
    assert_select "span", text: "+10%", count: 2
  end
end
