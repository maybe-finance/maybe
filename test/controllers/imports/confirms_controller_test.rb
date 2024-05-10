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
end
