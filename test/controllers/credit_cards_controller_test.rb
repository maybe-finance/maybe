require "test_helper"

class CreditCardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @credit_card = credit_cards(:one)
  end

  test "new" do
    get new_credit_card_path
    assert_response :success
  end

  test "show" do
    get credit_card_url(@credit_card)
    assert_response :success
  end

  test "creates credit card" do
    assert_difference -> { Account.count } => 1,
      -> { CreditCard.count } => 1,
      -> { Account::Valuation.count } => 2,
      -> { Account::Entry.count } => 2 do
      post credit_cards_path, params: {
        credit_card: {
          name: "New Credit Card",
          balance: 1000,
          currency: "USD",
          accountable_type: "CreditCard",
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
    assert_equal "Credit card account created", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates credit card" do
    assert_no_difference [ "Account.count", "CreditCard.count" ] do
      patch credit_card_path(@credit_card), params: {
        credit_card: {
          name: "Updated Credit Card",
          balance: 2000,
          currency: "USD",
          accountable_type: "CreditCard",
          accountable_attributes: {
            id: @credit_card.id,
            available_credit: 6000,
            minimum_payment: 50,
            apr: 14.99,
            expiration_date: 3.years.from_now.to_date,
            annual_fee: 0
          }
        }
      }
    end

    @credit_card.reload

    assert_equal "Updated Credit Card", @credit_card.account.name
    assert_equal 2000, @credit_card.account.balance
    assert_equal 6000, @credit_card.available_credit
    assert_equal 50, @credit_card.minimum_payment
    assert_equal 14.99, @credit_card.apr
    assert_equal 3.years.from_now.to_date, @credit_card.expiration_date
    assert_equal 0, @credit_card.annual_fee

    assert_redirected_to account_path(@credit_card.account)
    assert_equal "Credit card account updated", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
