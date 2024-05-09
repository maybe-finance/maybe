require "test_helper"

class Imports::LoadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "should get show" do
    import = imports(:completed_import)

    get import_load_url(import)
    assert_response :success
  end

  test "should save raw CSV if valid" do
    import = imports(:empty_import)
    valid_csv_format = <<-ROWS
      name,age
      John,20
      Jane,23
    ROWS

    patch import_load_url(import), params: { import: { raw_csv: valid_csv_format } }

    assert_redirected_to import_configure_path(import)
    assert_equal "Import uploaded", flash[:notice]
  end

  test "should flash error message if invalid CSV input" do
    import = imports(:empty_import)
    invalid_csv_format = <<-ROWS
      name,age
      "John Doe,23
      "Jane Doe",25
    ROWS

    patch import_load_url(import), params: { import: { raw_csv: invalid_csv_format } }

    assert_response :unprocessable_entity
    assert_equal "Raw csv is not a valid CSV format", flash[:error]
  end
end
