require "test_helper"

class AccountsHelperTest < ActionView::TestCase
  def setup
    @account1 = Account.new(currency: "USD", balance: 1)
    @account2 = Account.new(currency: "USD", balance: 2)
    @account3 = Account.new(currency: "EUR", balance: 7)
  end

  test "#format_accounts_balance(accounts)" do
    assert_equal "$3.00", format_accounts_balance([ @account1, @account2 ])
    assert_equal "$3.00, €7,00", format_accounts_balance([ @account1, @account2, @account3 ])
    assert_equal "", format_accounts_balance([])
    assert_equal "$0.00", format_accounts_balance([ Account.new(currency: "USD", balance: 0) ])
  end
end
