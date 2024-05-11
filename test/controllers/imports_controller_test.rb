require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)
    @imports = @user.family.imports.ordered.to_a
  end

  test "should get index" do
    get imports_url
    assert_response :success

    @imports.each do |import|
      assert_select "#" + dom_id(import), count: 1
    end
  end

  test "should get new" do
    get new_import_url
    assert_response :success
  end

  test "should create import" do
    assert_difference("Import.count") do
      post imports_url, params: { import: { account_id: @imports.first.account_id, column_mappings: @imports.first.column_mappings } }
    end

    assert_redirected_to load_import_path(Import.ordered.last)
  end

  test "should get edit" do
    get edit_import_url(@imports.first)
    assert_response :success
  end

  test "should update import" do
    patch import_url(@imports.first), params: { import: { account_id: @imports.first.account_id } }
    assert_redirected_to load_import_path(@imports.first)
  end

  test "should destroy import" do
    assert_difference("Import.count", -1) do
      delete import_url(@imports.first)
    end

    assert_redirected_to imports_url
  end

  test "should get load" do
    import = imports(:completed_import)

    get load_import_url(import)
    assert_response :success
  end

  test "should save raw CSV if valid" do
    import = imports(:empty_import)

    patch load_import_url(import), params: { import: { raw_csv: valid_csv_str } }

    assert_redirected_to configure_import_path(import)
    assert_equal "Import uploaded", flash[:notice]
  end

  test "should flash error message if invalid CSV input" do
    import = imports(:empty_import)

    patch load_import_url(import), params: { import: { raw_csv: malformed_csv_str } }

    assert_response :unprocessable_entity
    assert_equal "Raw csv is not a valid CSV format", flash[:error]
  end

  test "should get configure" do
    import = imports(:completed_import)

    get configure_import_url(import)
    assert_response :success
  end

  test "should update if mappings valid" do
    import = imports(:empty_import)
    import.raw_csv = valid_csv_str
    import.save!

    patch configure_import_url(import), params: {
      import: {
        column_mappings: {
          date: "date",
          merchant: "merchant",
          category: "category",
          amount: "amount"
        }
      }
    }

    assert_redirected_to clean_import_path(import)
    assert_equal "Mappings saved", flash[:notice]
  end

  test "should flash error if mappings are not valid" do
    import = imports(:empty_import)
    import.raw_csv = valid_csv_str
    import.save!

    patch configure_import_url(import), params: {
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

  test "should get clean" do
    import = imports(:empty_import)
    import.update! \
      raw_csv: valid_csv_str,
      column_mappings: import.default_column_mappings

    get clean_import_url(import)
    assert_response :success

    assert_dom "table tbody tr", import.parsed_csv.length
  end

  test "can update a cell" do
    import = imports(:empty_import)
    import.update! \
      raw_csv: valid_csv_str,
      column_mappings: import.default_column_mappings

    assert_equal import.parsed_csv[0][1], "Starbucks"

    patch clean_import_url(import), params: {
      csv_update: {
        row_idx: 0,
        col_idx: 1,
        value: "new_merchant"
      }
    }

    assert_response :success

    import.reload
    assert_equal "new_merchant", import.parsed_csv[0][1]
  end

  test "should get confirm if all values are valid" do
    import = imports(:empty_import)
    import.update! \
      raw_csv: valid_csv_str,
      column_mappings: import.default_column_mappings

    get confirm_import_url(import)
    assert_response :success
  end

  test "should redirect back to clean step if any values are invalid" do
    import = imports(:empty_import)
    import.update! \
      raw_csv: valid_csv_str,
      column_mappings: import.default_column_mappings

    import.update_cell! \
      row_idx: 0,
      col_idx: 0,
      value: "invalid date value"

    get confirm_import_url(import)
    assert_redirected_to clean_import_path(import)
    assert_equal "There are invalid values", flash[:error]
  end

  test "should confirm import" do
    import = imports(:empty_import)
    import.update! \
      raw_csv: valid_csv_str,
      column_mappings: import.default_column_mappings

    patch confirm_import_url(import)
    assert_redirected_to transactions_path
    assert_equal "Import complete!", flash[:notice]
  end
end
