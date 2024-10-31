require "test_helper"

class CryptosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @crypto = cryptos(:one)
  end

  test "new" do
    get new_crypto_url
    assert_response :success
  end

  test "show" do
    get crypto_url(@crypto)
    assert_response :success
  end

  test "create" do
    assert_difference [ "Account.count", "Crypto.count" ], 1 do
      post cryptos_url, params: {
        account: {
          accountable_type: "Crypto",
          name: "New crypto",
          balance: 10000,
          currency: "USD",
          subtype: "bitcoin"
        }
      }
    end

    assert_redirected_to Account.order(:created_at).last
    assert_equal "Crypto account created", flash[:notice]
  end

  test "update" do
    assert_no_difference [ "Account.count", "Crypto.count" ] do
      patch crypto_url(@crypto), params: {
        account: {
          name: "Updated name",
          balance: 10000,
          currency: "USD",
          subtype: "bitcoin"
        }
      }
    end

    assert_redirected_to @crypto.account
    assert_equal "Crypto account updated", flash[:notice]
  end
end
