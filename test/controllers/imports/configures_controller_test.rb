require "test_helper"
require "ostruct"

class Imports::ConfiguresControllerTest < ActionDispatch::IntegrationTest
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)
  end

  test "should get show" do
    import = imports(:completed_import)

    get import_configure_url(import)
    assert_response :success
  end

  test "should update if mappings valid" do
    import = imports(:empty_import)
    import.raw_csv = valid_csv_str
    import.save!

    patch import_configure_url(import), params: {
      import: {
        column_mappings: {
          date: "date",
          merchant: "merchant",
          category: "category",
          amount: "amount"
        }
      }
    }

    assert_redirected_to import_clean_path(import)
    assert_equal "Mappings saved", flash[:notice]
  end

  test "should flash error if mappings are not valid" do
    import = imports(:empty_import)
    import.raw_csv = valid_csv_str
    import.save!

    patch import_configure_url(import), params: {
      import: {
        column_mappings: {
          date: "invalid",
          merchant: "invalid",
          category: "invalid",
          amount: "invalid"
        }
      }
    }

    assert_response :unprocessable_entity
    assert_equal "column map has key date, but could not find date in raw csv input", flash[:error]
  end
end
