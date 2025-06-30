require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  include AccountableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:property)
  end

  test "creates property and redirects to value step" do
    assert_difference -> { Account.count } => 1 do
      post properties_path, params: {
        account: {
          name: "New Property",
          subtype: "house",
          accountable_type: "Property",
          balance: 0,
          currency: "USD",
          accountable_attributes: {
            year_built: 1990,
            area_value: 1200,
            area_unit: "sqft"
          }
        }
      }
    end

    created_account = Account.order(:created_at).last
    assert created_account.accountable.is_a?(Property)
    assert_equal 1990, created_account.accountable.year_built
    assert_equal 1200, created_account.accountable.area_value
    assert_equal "sqft", created_account.accountable.area_unit
    assert_redirected_to value_property_path(created_account)
  end

  test "updates property overview" do
    assert_no_difference [ "Account.count", "Property.count" ] do
      patch property_path(@account), params: {
        account: {
          name: "Updated Property",
          subtype: "condo"
        }
      }
    end

    @account.reload
    assert_equal "Updated Property", @account.name
    assert_equal "condo", @account.subtype
    assert_redirected_to value_property_path(@account)
  end

  # Tab view tests
  test "shows value tab" do
    get value_property_path(@account)
    assert_response :success
  end

  test "shows address tab" do
    get address_property_path(@account)
    assert_response :success
  end

  # Tab update tests
  test "updates value tab" do
    original_balance = @account.balance

    assert_no_difference [ "Account.count", "Property.count" ] do
      patch update_value_property_path(@account), params: {
        account: {
          balance: 600000,
          currency: "EUR"
        }
      }
    end

    @account.reload
    assert_not_equal original_balance, @account.balance
    assert_equal "EUR", @account.currency
    assert_redirected_to address_property_path(@account)
  end

  test "updates address tab" do
    assert_no_difference [ "Account.count", "Property.count" ] do
      patch update_address_property_path(@account), params: {
        account: {
          accountable_attributes: {
            id: @account.accountable_id,
            address_attributes: {
              line1: "456 New Street",
              locality: "San Francisco",
              region: "CA",
              country: "US",
              postal_code: "94102"
            }
          }
        }
      }
    end

    @account.reload
    assert_equal "456 New Street", @account.accountable.address.line1
    assert_equal "San Francisco", @account.accountable.address.locality

    assert_redirected_to @account
    assert_equal "Property updated successfully!", flash[:notice]
  end

  test "value update handles validation errors" do
    Account.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid.new(@account))

    patch update_value_property_path(@account), params: {
      account: {
        balance: 600000,
        currency: "EUR"
      }
    }

    assert_response :unprocessable_entity
  end

  test "address update handles validation errors" do
    Account.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid.new(@account))

    patch update_address_property_path(@account), params: {
      account: {
        accountable_attributes: {
          id: @account.accountable_id,
          address_attributes: {
            line1: "123 Test St"
          }
        }
      }
    }

    assert_response :unprocessable_entity
  end
end
