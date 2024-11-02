require "test_helper"

module AccountActionsInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "shows new form" do
    get new_polymorphic_url(@accountable)
    assert_response :success
  end

  test "shows edit form" do
    get edit_polymorphic_url(@accountable)
    assert_response :success
  end

  test "renders accountable page" do
    get polymorphic_url(@accountable)
    assert_response :success
  end

  test "updates basic account balances" do
    assert_no_difference [ "Account.count", "@accountable.class.count" ] do
      patch polymorphic_url(@accountable), params: {
        account: {
          institution_id: institutions(:chase).id,
          name: "Updated name",
          balance: 10000,
          currency: "USD"
        }
      }
    end

    assert_redirected_to @accountable
    assert_equal "#{@accountable.class.model_name.human} account updated", flash[:notice]
  end

  test "creates with basic attributes" do
    assert_difference [ "Account.count", "@accountable.class.count" ], 1 do
      post "/#{@accountable.class.model_name.collection}", params: {
        account: {
          accountable_type: @accountable.class.name,
          institution_id: institutions(:chase).id,
          name: "New accountable",
          balance: 10000,
          currency: "USD",
          subtype: "checking"
        }
      }
    end

    assert_redirected_to @accountable.class.order(:created_at).last
    assert_equal "#{@accountable.class.model_name.human} account created", flash[:notice]
  end

  test "updates account balance by creating new valuation" do
    assert_difference [ "Account::Entry.count", "Account::Valuation.count" ], 1 do
      patch polymorphic_url(@accountable), params: {
        account: {
          balance: 10000
        }
      }
    end

    assert_redirected_to @accountable
    assert_enqueued_with job: AccountSyncJob
    assert_equal "#{@accountable.class.model_name.human} account updated", flash[:notice]
  end

  test "updates account balance by editing existing valuation for today" do
    @accountable.account.entries.create! date: Date.current, amount: 6000, currency: "USD", entryable: Account::Valuation.new

    assert_no_difference [ "Account::Entry.count", "Account::Valuation.count" ] do
      patch polymorphic_url(@accountable), params: {
        account: {
          balance: 10000
        }
      }
    end

    assert_redirected_to @accountable
    assert_enqueued_with job: AccountSyncJob
    assert_equal "#{@accountable.class.model_name.human} account updated", flash[:notice]
  end
end
