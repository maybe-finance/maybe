require "test_helper"

class LoansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:loan)
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
          start_date: 1.month.ago.to_date,
          start_balance: 50000,
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
    assert_equal "Loan created successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates loan" do
    assert_no_difference [ "Account.count", "Loan.count" ] do
      patch loan_path(@account), params: {
        account: {
          name: "Updated Loan",
          balance: 45000,
          currency: "USD",
          accountable_type: "Loan",
          accountable_attributes: {
            id: @account.accountable_id,
            interest_rate: 4.5,
            term_months: 48,
            rate_type: "fixed"
          }
        }
      }
    end

    @account.reload

    assert_equal "Updated Loan", @account.name
    assert_equal 45000, @account.balance
    assert_equal 4.5, @account.loan.interest_rate
    assert_equal 48, @account.loan.term_months
    assert_equal "fixed", @account.loan.rate_type

    assert_redirected_to account_path(@account)
    assert_equal "Loan updated successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
