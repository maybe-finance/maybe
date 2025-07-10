require "test_helper"

class ValuationsControllerTest < ActionDispatch::IntegrationTest
  include EntryableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @entry = entries(:valuation)
  end

  test "creates entry with basic attributes" do
    account = accounts(:investment)

    assert_difference [ "Entry.count", "Valuation.count" ], 1 do
      post valuations_url, params: {
        entry: {
          amount: account.balance + 100,
          currency: "USD",
          date: Date.current.to_s,
          account_id: account.id
        }
      }
    end

    created_entry = Entry.order(created_at: :desc).first
    assert_equal "Manual value update", created_entry.name
    assert_equal Date.current, created_entry.date
    assert_equal account.balance + 100, created_entry.amount_money.to_f

    assert_enqueued_with job: SyncJob

    assert_redirected_to account_url(created_entry.account)
  end

  test "updates entry with basic attributes" do
    assert_no_difference [ "Entry.count", "Valuation.count" ] do
      patch valuation_url(@entry), params: {
        entry: {
          amount: 20000,
          currency: "USD",
          date: @entry.date
        }
      }
    end

    assert_enqueued_with job: SyncJob

    assert_redirected_to account_url(@entry.account)
  end
end
