require "test_helper"
require "ostruct"

class PlaidItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)

    @plaid_provider = mock

    PlaidItem.stubs(:plaid_provider).returns(@plaid_provider)
  end

  test "create" do
    public_token = "public-sandbox-1234"

    @plaid_provider.expects(:exchange_public_token).with(public_token).returns(
      OpenStruct.new(access_token: "access-sandbox-1234")
    )

    assert_difference "PlaidItem.count", 1 do
      post plaid_items_url, params: {
        plaid_item: {
          public_token: public_token,
          metadata: { institution: { name: "Plaid Item Name" } }
        }
      }
    end

    assert_equal "Account linked successfully.  Please wait for accounts to sync.", flash[:notice]
    assert_redirected_to accounts_path
  end

  test "destroy" do
    @plaid_provider.expects(:remove_item).once

    assert_difference [ "PlaidItem.count", "PlaidAccount.count", "Account.count" ], -1 do
      delete plaid_item_url(plaid_items(:one))
    end
  end
end
