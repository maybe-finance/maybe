require "test_helper"

class ValuationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @valuation = valuations(:savings_one)
    @account = @valuation.account
  end

  test "new" do
    get new_account_valuation_url(@account)
    assert_response :success
  end

  test "should create valuation" do
    assert_difference("Valuation.count") do
      post account_valuations_url(@account), params: { valuation: { value: 1, date: Date.current, type: "Appraisal" } }
    end
  end

  test "create should sync account with correct start date" do
    date = Date.current - 1.day

    assert_enqueued_with(job: AccountSyncJob, args: [@account, date]) do
      post account_valuations_url(@account), params: { valuation: { value: 2, date:, type: "Appraisal" } }
    end
  end

  test "should update valuation" do
    date = @valuation.date
    patch valuation_url(@valuation), params: { valuation: { account_id: @valuation.account_id, value: 1, date:, type: "Appraisal" } }
    assert_redirected_to account_path(@valuation.account)
  end

  test "update should sync account with correct start date" do
    new_date = @valuation.date - 1.day
    assert_enqueued_with(job: AccountSyncJob, args: [@account, new_date]) do
      patch valuation_url(@valuation), params: { valuation: { account_id: @valuation.account_id, value: @valuation.value, date: new_date, type: "Appraisal" } }
    end

    new_date = @valuation.reload.date + 1.day
    assert_enqueued_with(job: AccountSyncJob, args: [@account, @valuation.date]) do
      patch valuation_url(@valuation), params: { valuation: { account_id: @valuation.account_id, value: @valuation.value, date: new_date, type: "Appraisal" } }
    end
  end

  test "should destroy valuation" do
    assert_difference("Valuation.count", -1) do
      delete valuation_url(@valuation)
    end

    assert_redirected_to account_path(@account)
  end

  test "destroy should sync account with correct start date" do
    first, second = @account.valuations.order(:date).all

    assert_enqueued_with(job: AccountSyncJob, args: [@account, first.date]) do
      delete valuation_url(second)
    end

    assert_enqueued_with(job: AccountSyncJob, args: [@account, nil]) do
      delete valuation_url(first)
    end
  end
end
