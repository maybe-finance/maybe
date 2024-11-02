require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  include AccountActionsInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @accountable = @property = properties(:one)
  end

  test "creates with property details" do
    assert_difference -> { Account.count } => 1,
      -> { Property.count } => 1,
      -> { Account::Valuation.count } => 2,
      -> { Account::Entry.count } => 2 do
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

    created_property = Property.order(:created_at).last

    assert created_property.year_built.present?
    assert created_property.address.line1.present?

    assert_redirected_to created_property
    assert_equal "Property account created", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates with property details" do
    assert_no_difference [ "Account.count", "Property.count" ] do
      patch property_path(@property), params: {
        account: {
          name: "Updated Property",
          balance: 500000,
          currency: "USD",
          accountable_type: "Property",
          accountable_attributes: {
            id: @property.id,
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

    assert_redirected_to @property
    assert_equal "Property account updated", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
