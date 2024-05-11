require "test_helper"

class Imports::RowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "should update row" do
    row = import_rows(:one)

    patch import_row_url(row.import, row), params: {
      import_row: {
        name: "new name",
        date: "2024-01-01",
        category: "shopping",
        merchant: "amazon",
        amount: "20.40"
      }
    }

    assert_redirected_to clean_import_path(row.import)
  end
end
