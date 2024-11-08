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
      OpenStruct.new(access_token: "access-sandbox-1234", item_id: "item-sandbox-1234")
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

    assert_equal "Accounts removed successfully", flash[:notice]
    assert_redirected_to accounts_path
  end

  test "sync" do
    plaid_item = plaid_items(:one)
    PlaidItem.any_instance.expects(:sync_later).once

    post sync_plaid_item_url(plaid_item)

    assert_equal "Sync started", flash[:notice]
    assert_redirected_to accounts_path
  end
end
