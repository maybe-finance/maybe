require "test_helper"

class LoansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @loan = loans(:one)
  end

  test "new" do
    get new_loan_path
    assert_response :success
  end

  test "show" do
    get loan_url(@loan)
    assert_response :success
  end

  test "creates loan" do
    assert_difference -> { Account.count } => 1,
      -> { Loan.count } => 1,
      -> { Account::Valuation.count } => 2,
      -> { Account::Entry.count } => 2 do
      post loans_path, params: {
        account: {
          name: "New Loan",
          balance: 50000,
          currency: "USD",
          accountable_type: "Loan",
          accountable_attributes: {
            interest_rate: 5.5,
            term_months: 60,
            rate_type: "fixed"
          }
        }
      }
    end

    created_account = Account.order(:created_at).last

    assert_equal "New Loan", created_account.name
    assert_equal 50000, created_account.balance
    assert_equal "USD", created_account.currency
    assert_equal 5.5, created_account.loan.interest_rate
    assert_equal 60, created_account.loan.term_months
    assert_equal "fixed", created_account.loan.rate_type

    assert_redirected_to account_path(created_account)
    assert_equal "Loan account created", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates loan" do
    assert_no_difference [ "Account.count", "Loan.count" ] do
      patch loan_path(@loan), params: {
        account: {
          name: "Updated Loan",
          balance: 45000,
          currency: "USD",
          accountable_type: "Loan",
          accountable_attributes: {
            id: @loan.id,
            interest_rate: 4.5,
            term_months: 48,
            rate_type: "fixed"
          }
        }
      }
    end

    @loan.reload

    assert_equal "Updated Loan", @loan.account.name
    assert_equal 45000, @loan.account.balance
    assert_equal 4.5, @loan.interest_rate
    assert_equal 48, @loan.term_months
    assert_equal "fixed", @loan.rate_type

    assert_redirected_to account_path(@loan.account)
    assert_equal "Loan account updated", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
