require "test_helper"

class PlaidItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)

    Plaid::PlaidApi.any_instance.stubs(:item_public_token_exchange).returns(
      Plaid::ItemPublicTokenExchangeResponse.new(access_token: "access-sandbox-1234")
    )
  end

  test "create" do
    assert_difference "PlaidItem.count", 1 do
      post plaid_items_url, params: {
        plaid_item: { public_token: "public-sandbox-1234" }
      }
    end

    assert_equal "Account linked successfully.  Please wait for accounts to sync.", flash[:notice]
    assert_redirected_to accounts_path
  end
end
