require "test_helper"

class Imports::ConfirmsControllerTest < ActionDispatch::IntegrationTest
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)

    @import = imports(:empty_import)
    @import.update! \
      raw_csv: valid_csv_str,
      column_mappings: @import.default_column_mappings
  end

  test "should get show if all values are valid" do
    get import_confirm_url(@import)
    assert_response :success
  end

  test "should redirect back to clean step if any values are invalid" do
    @import.update_cell! \
      row_idx: 0,
      col_idx: 0,
      value: "invalid date value"

    get import_confirm_url(@import)
    assert_redirected_to clean_import_path(@import)
    assert_equal "There are invalid values", flash[:error]
  end

  test "should confirm import" do
    patch import_confirm_url(@import)
    assert_redirected_to transactions_path
    assert_equal "Import complete!", flash[:notice]
  end
end
