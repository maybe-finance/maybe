require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  include AccountableResourceInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:property)
  end

  test "creates property in draft status with initial balance information and redirects to details step" do
    assert_difference -> { Account.count } => 1 do
      post properties_path, params: {
        account: {
          name: "New Property",
          purchase_price: "250000",
          purchase_date: "2023-01-01",
          current_estimated_value: "300000",
          currency: "USD"
        }
      }
    end

    created_account = Account.order(:created_at).last
    assert created_account.accountable.is_a?(Property)
    assert_equal "draft", created_account.status
    assert_equal "New Property", created_account.name
    assert_equal 300_000, created_account.balance
    assert_equal 0, created_account.cash_balance
    assert_equal "USD", created_account.currency

    # Check opening balance was set
    opening_valuation = created_account.valuations.opening_anchor.first
    assert_not_nil opening_valuation
    assert_equal 250_000, opening_valuation.balance
    assert_equal Date.parse("2023-01-01"), opening_valuation.entry.date

    assert_redirected_to details_property_path(created_account)
  end

  test "updates property overview with balance information" do
    assert_no_difference [ "Account.count", "Property.count" ] do
      patch property_path(@account), params: {
        account: {
          name: "Updated Property",
          current_estimated_value: "350000",
          currency: "USD"
        }
      }
    end

    @account.reload
    assert_equal "Updated Property", @account.name
    assert_equal 350_000, @account.balance
    assert_equal 0, @account.cash_balance

    # If account is active, it renders edit view; otherwise redirects to details
    if @account.active?
      assert_response :success
    else
      assert_redirected_to details_property_path(@account)
    end
  end

  # Tab view tests
  test "shows details tab" do
    get details_property_path(@account)
    assert_response :success
  end

  test "shows address tab" do
    get address_property_path(@account)
    assert_response :success
  end

  # Tab update tests
  test "updates property details" do
    patch update_details_property_path(@account), params: {
      account: {
        subtype: "condo",
        accountable_attributes: {
          year_built: 2005,
          area_value: 1500,
          area_unit: "sqft"
        }
      }
    }

    @account.reload
    assert_equal "condo", @account.subtype
    assert_equal 2005, @account.accountable.year_built
    assert_equal 1500, @account.accountable.area_value
    assert_equal "sqft", @account.accountable.area_unit

    # If account is active, it renders details view; otherwise redirects to address
    if @account.active?
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
