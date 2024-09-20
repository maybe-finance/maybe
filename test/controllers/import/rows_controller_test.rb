require "test_helper"

class Import::RowsControllerTest < ActionDispatch::IntegrationTest
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)
    @empty_import = imports(:empty_import)

    @loaded_import = @empty_import.dup
    @loaded_import.update! raw_file_str: valid_csv_str, column_mappings: valid_column_mappings

    @completed_import = imports(:completed_import)
  end

  test "can update the name cell of the first row" do
    row = @loaded_import.rows.find_by(index: 0)

    assert_equal "Starbucks drink", row.name

    patch import_row_path(import_id: @loaded_import.id, id: row.id), params: {
      import_row: { name: "new_merchant" }
    }

    assert_response :redirect

    row.reload
    assert_equal "new_merchant", row.name
  end

  test "can update the date cell on the last row" do
    row = @loaded_import.rows.find_by(index: 3)

    assert_equal "2024-01-03", row.date

    patch import_row_path(import_id: @loaded_import.id, id: row.id), params: {
      import_row: { date: "2024-01-04" }
    }

    assert_response :redirect

    row.reload
    assert_equal "2024-01-04", row.date
  end
end
