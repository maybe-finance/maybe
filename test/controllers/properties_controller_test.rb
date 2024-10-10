require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:property)
  end

  test "creates property" do
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
          start_date: 3.years.ago.to_date,
          start_balance: 450000,
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

    assert created_account.property.year_built.present?
    assert created_account.property.address.line1.present?

    assert_redirected_to account_path(created_account)
    assert_equal "Property created successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "updates property" do
    assert_no_difference [ "Account.count", "Property.count" ] do
      patch property_path(@account), params: {
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

    assert_redirected_to account_path(@account)
    assert_equal "Property updated successfully", flash[:notice]
    assert_enqueued_with(job: AccountSyncJob)
  end
end
