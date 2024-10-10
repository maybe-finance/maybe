require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:vehicle)
  end

  test "creates vehicle" do
    assert_difference -> { Account.count } => 1,
      -> { Vehicle.count } => 1,
      -> { Account::Valuation.count } => 2,
      -> { Account::Entry.count } => 2 do
      post vehicles_path, params: {
        account: {
          name: "Vehicle",
          balance: 30000,
          currency: "USD",
          accountable_type: "Vehicle",
          start_date: 1.year.ago.to_date,
          start_balance: 35000,
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

    assert_equal "Toyota", created_account.vehicle.make
    assert_equal "Camry", created_account.vehicle.model
    assert_equal 2020, created_account.vehicle.year
    assert_equal 15000, created_account.vehicle.mileage_value
    assert_equal "mi", created_account.vehicle.mileage_unit

    assert_redirected_to account_path(created_account)
    assert_equal "Vehicle created successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates vehicle" do
    assert_no_difference [ "Account.count", "Vehicle.count" ] do
      patch vehicle_path(@account), params: {
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

    assert_redirected_to account_path(@account)
    assert_equal "Vehicle updated successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
