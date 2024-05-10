require "test_helper"

class Imports::CleansControllerTest < ActionDispatch::IntegrationTest
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)

    @import = imports(:empty_import)
    @import.update! \
      raw_csv: valid_csv_str,
      column_mappings: @import.default_column_mappings
  end

  test "should get show" do
    get import_clean_url(@import)
    assert_response :success

    assert_dom "table tbody tr", @import.parsed_csv.length
  end

  test "can update a cell" do
    assert_equal @import.parsed_csv[0][1], "Starbucks"

    patch import_clean_url(@import), params: {
      csv_update: {
        row_idx: 0,
        col_idx: 1,
        value: "new_merchant"
      }
    }

    assert_response :success

    @import.reload
    assert_equal "new_merchant", @import.parsed_csv[0][1]
  end
end
