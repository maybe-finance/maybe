require "test_helper"

class DepositoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @depository = depositories(:one)
  end

  test "new" do
    get new_depository_url
    assert_response :success
  end

  test "create" do
    assert_difference [ "Account.count", "Depository.count" ], 1 do
      post depositories_url, params: {
        depository: {
          name: "New depository",
          balance: 10000,
          currency: "USD",
          subtype: "checking"
        }
      }
    end

    assert_redirected_to Account.order(:created_at).last
    assert_equal "Depository account created", flash[:notice]
  end

  test "update" do
    assert_no_difference [ "Account.count", "Depository.count" ] do
      patch depository_url(@depository), params: {
        depository: {
          name: "Updated name",
          balance: 10000,
          currency: "USD",
          subtype: "checking"
        }
      }
    end

    assert_redirected_to @depository
    assert_equal "Depository account updated", flash[:notice]
  end
end
