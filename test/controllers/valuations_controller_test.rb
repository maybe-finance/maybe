require "test_helper"

class ValuationsControllerTest < ActionDispatch::IntegrationTest
  include EntryableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @entry = entries(:valuation)
  end

  test "error when valuation already exists for date" do
    assert_no_difference [ "Entry.count", "Valuation.count" ] do
      post valuations_url(@entry.account), params: {
        entry: {
          account_id: @entry.account_id,
          amount: 19800,
          date: @entry.date,
          currency: "USD"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "creates entry with basic attributes" do
    assert_difference [ "Entry.count", "Valuation.count" ], 1 do
      post valuations_url, params: {
        entry: {
          name: "New entry",
          amount: 10000,
          currency: "USD",
          date: Date.current,
          account_id: @entry.account_id
        }
      }
    end

    created_entry = Entry.order(created_at: :desc).first

    assert_enqueued_with job: SyncJob

    assert_redirected_to account_url(created_entry.account)
  end

  test "updates entry with basic attributes" do
    assert_no_difference [ "Entry.count", "Valuation.count" ] do
      patch valuation_url(@entry), params: {
        entry: {
          name: "Updated entry",
          amount: 20000,
          currency: "USD",
          date: Date.current
        }
      }
    end

    assert_enqueued_with job: SyncJob

    assert_redirected_to account_url(@entry.account)
  end
end
