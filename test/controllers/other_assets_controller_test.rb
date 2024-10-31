require "test_helper"

class OtherAssetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @other_asset = other_assets(:one)
  end

  test "new" do
    get new_other_asset_url
    assert_response :success
  end

  test "show" do
    get other_asset_url(@other_asset)
    assert_response :success
  end

  test "create" do
    assert_difference [ "Account.count", "OtherAsset.count" ], 1 do
      post other_assets_url, params: {
        account: {
          accountable_type: "OtherAsset",
          name: "New other asset",
          balance: 5000,
          currency: "USD",
          subtype: "other"
        }
      }
    end

    assert_redirected_to Account.order(:created_at).last
    assert_equal "Other asset account created", flash[:notice]
  end

  test "update" do
    assert_no_difference [ "Account.count", "OtherAsset.count" ] do
      patch other_asset_url(@other_asset), params: {
        account: {
          name: "Updated name",
          balance: 5000,
          currency: "USD",
          subtype: "other"
        }
      }
    end

    assert_redirected_to @other_asset.account
    assert_equal "Other asset account updated", flash[:notice]
  end
end
