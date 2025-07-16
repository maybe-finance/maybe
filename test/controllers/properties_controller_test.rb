require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  include AccountableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:property)
  end

  test "creates property in draft status and redirects to balances step" do
    assert_difference -> { Account.count } => 1 do
      post properties_path, params: {
        account: {
          name: "New Property",
          subtype: "house",
          accountable_type: "Property",
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
    assert_equal "draft", created_account.status
    assert_equal 0, created_account.balance
    assert_equal 1990, created_account.accountable.year_built
    assert_equal 1200, created_account.accountable.area_value
    assert_equal "sqft", created_account.accountable.area_unit
    assert_redirected_to balances_property_path(created_account)
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

    # If account is active, it renders edit view; otherwise redirects to balances
    if @account.active?
      assert_response :success
    else
      assert_redirected_to balances_property_path(@account)
    end
  end

  # Tab view tests
  test "shows balances tab" do
    get balances_property_path(@account)
    assert_response :success
  end

  test "shows address tab" do
    get address_property_path(@account)
    assert_response :success
  end

  # Tab update tests
  test "updates balances tab" do
    original_balance = @account.balance

    patch update_balances_property_path(@account), params: {
      account: {
        balance: 600000,
        currency: "EUR"
      }
    }

    # If account is active, it renders balances view; otherwise redirects to address
    if @account.reload.active?
      assert_response :success
    else
      assert_redirected_to address_property_path(@account)
    end
  end

  test "updates address tab" do
    patch update_address_property_path(@account), params: {
      property: {
        address_attributes: {
          line1: "456 New Street",
          locality: "San Francisco",
          region: "CA",
          country: "US",
          postal_code: "94102"
        }
      }
    }

    @account.reload
    assert_equal "456 New Street", @account.accountable.address.line1
    assert_equal "San Francisco", @account.accountable.address.locality

    # If account is draft, it activates and redirects; otherwise renders address
    if @account.draft?
      assert_redirected_to account_path(@account)
    else
      assert_response :success
    end
  end

  test "balances update handles validation errors" do
    Account.any_instance.stubs(:set_current_balance).returns(OpenStruct.new(success?: false, error_message: "Invalid balance"))

    patch update_balances_property_path(@account), params: {
      account: {
        balance: 600000,
        currency: "EUR"
      }
    }

    assert_response :unprocessable_entity
  end

  test "address update handles validation errors" do
    Property.any_instance.stubs(:update).returns(false)

    patch update_address_property_path(@account), params: {
      property: {
        address_attributes: {
          line1: "123 Test St"
        }
      }
    }

    assert_response :unprocessable_entity
  end

  test "address update activates draft account" do
    # Create a draft property account
    draft_account = Account.create!(
      family: @user.family,
      name: "Draft Property",
      accountable: Property.new,
      status: "draft",
      balance: 500000,
      currency: "USD"
    )

    assert draft_account.draft?

    patch update_address_property_path(draft_account), params: {
      property: {
        address_attributes: {
          line1: "789 Activate St",
          locality: "New York",
          region: "NY",
          country: "US",
          postal_code: "10001"
        }
      }
    }

    draft_account.reload
    assert draft_account.active?
    assert_redirected_to account_path(draft_account)
  end
end
