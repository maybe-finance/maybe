require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  include AccountableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:property)
  end

  test "creates with property details" do
    assert_difference -> { Account.count } => 1,
      -> { Property.count } => 1,
      -> { Valuation.count } => 2,
      -> { Entry.count } => 2 do
      post properties_path, params: {
        account: {
          name: "Property",
          balance: 500000,
          currency: "USD",
          accountable_type: "Property",
          accountable_attributes: {
            year_built: 2002,
            area_value: 1000,
            area_unit: "sqft",
            address_attributes: {
              line1: "123 Main St",
              line2: "Apt 1",
              locality: "Los Angeles",
              region: "CA", # ISO3166-2 code
              country: "US", # ISO3166-1 Alpha-2 code
              postal_code: "90001"
            }
          }
        }
      }
    end

    created_account = Account.order(:created_at).last

    assert created_account.accountable.year_built.present?
    assert created_account.accountable.address.line1.present?

    assert_redirected_to created_account
    assert_equal "Property account created", flash[:notice]
    assert_enqueued_with(job: SyncJob)
  end

  test "updates with property details" do
    assert_no_difference [ "Account.count", "Property.count" ] do
      patch account_path(@account), params: {
        account: {
          name: "Updated Property",
          balance: 500000,
          currency: "USD",
          accountable_type: "Property",
          accountable_attributes: {
            id: @account.accountable_id,
            year_built: 2002,
            area_value: 1000,
            area_unit: "sqft",
            address_attributes: {
              line1: "123 Main St",
              line2: "Apt 1",
              locality: "Los Angeles",
              region: "CA", # ISO3166-2 code
              country: "US", # ISO3166-1 Alpha-2 code
              postal_code: "90001"
            }
          }
        }
      }
    end

    assert_redirected_to @account
    assert_equal "Property account updated", flash[:notice]
    assert_enqueued_with(job: SyncJob)
  end
end
