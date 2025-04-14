require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  include AccountableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:vehicle)
  end

  test "creates with vehicle details" do
    assert_difference -> { Account.count } => 1,
      -> { Vehicle.count } => 1,
      -> { Valuation.count } => 2,
      -> { Entry.count } => 2 do
      post vehicles_path, params: {
        account: {
          name: "Vehicle",
          balance: 30000,
          currency: "USD",
          accountable_type: "Vehicle",
          accountable_attributes: {
            make: "Toyota",
            model: "Camry",
            year: 2020,
            mileage_value: 15000,
            mileage_unit: "mi"
          }
        }
      }
    end

    created_account = Account.order(:created_at).last

    assert_equal "Toyota", created_account.accountable.make
    assert_equal "Camry", created_account.accountable.model
    assert_equal 2020, created_account.accountable.year
    assert_equal 15000, created_account.accountable.mileage_value
    assert_equal "mi", created_account.accountable.mileage_unit

    assert_redirected_to created_account
    assert_equal "Vehicle account created", flash[:notice]
    assert_enqueued_with(job: SyncJob)
  end

  test "updates with vehicle details" do
    assert_no_difference [ "Account.count", "Vehicle.count" ] do
      patch account_path(@account), params: {
        account: {
          name: "Updated Vehicle",
          balance: 28000,
          currency: "USD",
          accountable_type: "Vehicle",
          accountable_attributes: {
            id: @account.accountable_id,
            make: "Honda",
            model: "Accord",
            year: 2021,
            mileage_value: 20000,
            mileage_unit: "mi",
            purchase_price: 32000
          }
        }
      }
    end

    assert_redirected_to @account
    assert_equal "Vehicle account updated", flash[:notice]
    assert_enqueued_with(job: SyncJob)
  end
end
