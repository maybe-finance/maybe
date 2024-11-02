require "test_helper"

class LoansControllerTest < ActionDispatch::IntegrationTest
  include AccountActionsInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @accountable = @loan = loans(:one)
  end

  test "creates with loan details" do
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

    created_loan = Loan.order(:created_at).last

    assert_equal "New Loan", created_loan.account.name
    assert_equal 50000, created_loan.account.balance
    assert_equal "USD", created_loan.account.currency
    assert_equal 5.5, created_loan.interest_rate
    assert_equal 60, created_loan.term_months
    assert_equal "fixed", created_loan.rate_type

    assert_redirected_to created_loan
    assert_equal "Loan account created", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates with loan details" do
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

    assert_redirected_to @loan
    assert_equal "Loan account updated", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
