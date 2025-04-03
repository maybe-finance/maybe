require "test_helper"

class MerchantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @merchant = merchants(:netflix)
  end

  test "index" do
    get merchants_path
    assert_response :success
  end

  test "new" do
    get new_merchant_path
    assert_response :success
  end

  test "should create merchant" do
    assert_difference("Merchant.count") do
      post merchants_url, params: { merchant: { name: "new merchant", color: "#000000" } }
    end

    assert_redirected_to merchants_path
  end

  test "should update merchant" do
    patch merchant_url(@merchant), params: { merchant: { name: "new name", color: "#000000" } }
    assert_redirected_to merchants_path
  end

  test "should destroy merchant" do
    assert_difference("Merchant.count", -1) do
      delete merchant_url(@merchant)
    end

    assert_redirected_to merchants_path
  end
end
