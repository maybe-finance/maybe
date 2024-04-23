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

  test "should sync account after create" do
    date = Date.current - 1.day
    value = 2

    @account.sync

    assert_changes("@account.balance_on(date)", to: value) do
      post account_valuations_url(@account), params: { valuation: { value:, date:, type: "Appraisal" } }
      perform_enqueued_jobs
    end
  end

  test "should do a partial account sync after create" do
    date = Date.current - 1.day
    @account.sync
    @account.balances.where(date: date - 1.day).update!(balance: 200)

    assert_no_changes("@account.balance_on(date - 1.day)") do
      post account_valuations_url(@account), params: { valuation: { value: 1, date:, type: "Appraisal" } }
      perform_enqueued_jobs
    end
  end

  test "should update valuation" do
    date = @valuation.date
    patch valuation_url(@valuation), params: { valuation: { account_id: @valuation.account_id, value: 1, date:, type: "Appraisal" } }
    assert_redirected_to account_path(@valuation.account)
  end

  test "should sync account after update" do
    account = @valuation.account
    date = @valuation.date
    value = 2

    account.sync

    assert_changes("account.balance_on(date)", value) do
      patch valuation_url(@valuation), params: { valuation: { account_id: @valuation.account_id, value:, date:, type: "Appraisal" } }
      perform_enqueued_jobs
    end
  end

  test "should do a partial account sync after update" do
    account = @valuation.account
    date = @valuation.date
    value = 2

    account.sync
    account.balances.where(date: date - 2.day).update!(balance: 200)

    assert_no_changes("account.balance_on(date - 2.day)") do
      patch valuation_url(@valuation), params: { valuation: { account_id: @valuation.account_id, value:, date:, type: "Appraisal" } }
      perform_enqueued_jobs
    end
  end

  test "should destroy valuation" do
    assert_difference("Valuation.count", -1) do
      delete valuation_url(@valuation)
    end

    assert_redirected_to account_path(@account)
  end

  test "should sync account after destroy" do
    account = @valuation.account
    date = @valuation.date
    value = @account.balance
    account.sync

    assert_changes("@account.balance_on(date)", to: 19700) do
      delete valuation_url(@valuation)
      perform_enqueued_jobs
    end
  end

  test "should do a partial account sync after destroy" do
    account = @valuation.account
    date = @valuation.date

    account.sync
    account.balances.where(date: date - 10.day).update!(balance: 200)

    assert_no_changes("account.balance_on(date - 10.day)") do
      delete valuation_url(@valuation)
      perform_enqueued_jobs
    end
  end
end
