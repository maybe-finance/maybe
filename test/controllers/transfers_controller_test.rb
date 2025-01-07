require "test_helper"

class TransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "should get new" do
    get new_transfer_url
    assert_response :success
  end

  test "can create transfers" do
    assert_difference "Transfer.count", 1 do
      post transfers_url, params: {
        transfer: {
          from_account_id: accounts(:depository).id,
          to_account_id: accounts(:credit_card).id,
          date: Date.current,
          amount: 100,
          name: "Test Transfer"
        }
      }
      assert_enqueued_with job: SyncJob
    end
  end

  test "can destroy transfer" do
    assert_difference -> { Transfer.count } => -1, -> { Account::Transaction.count } => 0 do
      delete transfer_url(transfers(:one))
    end
  end
end
