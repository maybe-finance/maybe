require "test_helper"

class AccountsHelperTest < ActionView::TestCase
  class AccountHumanizerTest < AccountsHelperTest
    test "no type in params" do
      params[:type] = nil
      assert_equal Account.name, humanized_account
    end
    test "Depository in params" do
      params[:type] = "Depository"
      assert_equal "Bank Account", humanized_account
    end
    test "unrecognized param" do
      params[:type] = "Biscuit"
      assert_equal Account.name, humanized_account
    end
  end
  class AccountTypesTest < AccountsHelperTest
    test "no type in params" do
      params[:type] = nil
      assert_equal Account.name, account_type.name
    end

    test "allowed params" do
      Account.accountable_types.each do |type|
        params[:type] = type.split("::").last
        assert_equal type, account_type.name
      end
    end

    test "unrecognized param" do
      params[:type] = "Biscuit"
      assert_equal Account.name, account_type.name
    end
  end
end
