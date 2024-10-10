require "test_helper"

class CreditCardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:credit_card)
  end

  test "creates credit card" do
    assert_difference -> { Account.count } => 1,
      -> { CreditCard.count } => 1,
      -> { Account::Valuation.count } => 2,
      -> { Account::Entry.count } => 2 do
      post credit_cards_path, params: {
        account: {
          name: "New Credit Card",
          balance: 1000,
          currency: "USD",
          accountable_type: "CreditCard",
          start_date: 1.month.ago.to_date,
          start_balance: 0,
          accountable_attributes: {
            available_credit: 5000,
            minimum_payment: 25,
            apr: 15.99,
            expiration_date: 2.years.from_now.to_date,
            annual_fee: 99
          }
        }
      }
    end

    created_account = Account.order(:created_at).last

    assert_equal "New Credit Card", created_account.name
    assert_equal 1000, created_account.balance
    assert_equal "USD", created_account.currency
    assert_equal 5000, created_account.credit_card.available_credit
    assert_equal 25, created_account.credit_card.minimum_payment
    assert_equal 15.99, created_account.credit_card.apr
    assert_equal 2.years.from_now.to_date, created_account.credit_card.expiration_date
    assert_equal 99, created_account.credit_card.annual_fee

    assert_redirected_to account_path(created_account)
    assert_equal "Credit card created successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates credit card" do
    assert_no_difference [ "Account.count", "CreditCard.count" ] do
      patch credit_card_path(@account), params: {
        account: {
          name: "Updated Credit Card",
          balance: 2000,
          currency: "USD",
          accountable_type: "CreditCard",
          accountable_attributes: {
            id: @account.accountable_id,
            available_credit: 6000,
            minimum_payment: 50,
            apr: 14.99,
            expiration_date: 3.years.from_now.to_date,
            annual_fee: 0
          }
        }
      }
    end

    @account.reload

    assert_equal "Updated Credit Card", @account.name
    assert_equal 2000, @account.balance
    assert_equal 6000, @account.credit_card.available_credit
    assert_equal 50, @account.credit_card.minimum_payment
    assert_equal 14.99, @account.credit_card.apr
    assert_equal 3.years.from_now.to_date, @account.credit_card.expiration_date
    assert_equal 0, @account.credit_card.annual_fee

    assert_redirected_to account_path(@account)
    assert_equal "Credit card updated successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
