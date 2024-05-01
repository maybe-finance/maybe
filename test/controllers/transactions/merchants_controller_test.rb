require "test_helper"

class Transactions::MerchantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @merchant = transaction_merchants(:netflix)
  end

  test "index" do
    get transaction_merchants_path
    assert_response :success
  end

  test "new" do
    get new_transaction_merchant_path
    assert_response :success
  end

  test "should create merchant" do
    assert_difference("Transaction::Merchant.count") do
      post transaction_merchants_url, params: { transaction_merchant: { name: "new merchant", color: "#000000" } }
    end

    assert_redirected_to transaction_merchants_path
  end

  test "should update merchant" do
    patch transaction_merchant_url(@merchant), params: { transaction_merchant: { name: "new name", color: "#000000" } }
    assert_redirected_to transaction_merchants_path
  end

  test "should destroy merchant" do
    assert_difference("Transaction::Merchant.count", -1) do
      delete transaction_merchant_url(@merchant)
    end

    assert_redirected_to transaction_merchants_path
  end
end
