require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)
    @empty_import = imports(:empty_import)

    @loaded_import = @empty_import.dup
    @loaded_import.update! raw_csv_str: valid_csv_str

    @completed_import = imports(:completed_import)
  end

  test "should get index" do
    get imports_url
    assert_response :success

    @user.family.imports.ordered.each do |import|
      assert_select "#" + dom_id(import), count: 1
    end
  end

  test "should get new" do
    get new_import_url
    assert_response :success
  end

  test "should create import" do
    assert_difference("Import.count") do
      post imports_url, params: { import: { account_id: @user.family.accounts.first.id, col_sep: "," } }
    end

    assert_redirected_to load_import_path(Import.ordered.first)
  end

  test "should get edit" do
    get edit_import_url(@empty_import)
    assert_response :success
  end

  test "should update import" do
    patch import_url(@empty_import), params: { import: { account_id: @empty_import.account_id, col_sep: "," } }
    assert_redirected_to load_import_path(@empty_import)
  end

  test "should destroy import" do
    assert_difference("Import.count", -1) do
      delete import_url(@empty_import)
    end

    assert_redirected_to imports_url
  end

  test "should get load" do
    get load_import_url(@empty_import)
    assert_response :success
  end

  test "should save raw CSV if valid" do
    patch load_import_url(@empty_import), params: { import: { raw_csv_str: valid_csv_str } }

    assert_redirected_to configure_import_path(@empty_import)
    assert_equal "Import CSV loaded", flash[:notice]
  end

  test "should upload CSV file if valid" do
    Tempfile.open([ "transactions.csv", ".csv" ]) do |temp|
      CSV.open(temp, "wb", headers: true) do |csv|
        valid_csv_str.split("\n").each { |row| csv << row.split(",") }
      end

      patch upload_import_url(@empty_import), params: { import: { raw_csv_str: Rack::Test::UploadedFile.new(temp, ".csv") } }
      assert_redirected_to configure_import_path(@empty_import)
      assert_equal "CSV File loaded", flash[:notice]
    end
  end

  test "should flash error message if invalid CSV input" do
    patch load_import_url(@empty_import), params: { import: { raw_csv_str: malformed_csv_str } }

    assert_response :unprocessable_entity
    assert_equal "Raw csv str is not a valid CSV format", flash[:alert]
  end

  test "should flash error message if invalid CSV file upload" do
    Tempfile.open([ "transactions.csv", ".csv" ]) do |temp|
      temp.write(malformed_csv_str)
      temp.rewind

      patch upload_import_url(@empty_import), params: { import: { raw_csv_str: Rack::Test::UploadedFile.new(temp, ".csv") } }
      assert_response :unprocessable_entity
      assert_equal "Raw csv str is not a valid CSV format", flash[:alert]
    end
  end

  test "should flash error message if no fileprovided for upload" do
    patch upload_import_url(@empty_import), params: { import: { raw_csv_str: nil } }
    assert_response :unprocessable_entity
    assert_equal "Please select a file to upload", flash[:alert]
  end

  test "should get configure" do
    get configure_import_url(@loaded_import)
    assert_response :success
  end

  test "should redirect back to load step with an alert message if not loaded" do
    get configure_import_url(@empty_import)
    assert_equal "Please load a CSV first", flash[:alert]
    assert_redirected_to load_import_path(@empty_import)
  end

  test "should update mappings" do
    patch configure_import_url(@loaded_import), params: {
      import: {
        column_mappings: {
          date: "date",
          name: "name",
          category: "category",
          amount: "amount"
        }
      }
    }

    assert_redirected_to clean_import_path(@loaded_import)
    assert_equal "Column mappings saved", flash[:notice]
  end

  test "can update a cell" do
    assert_equal @loaded_import.csv.table[0][1], "Starbucks drink"

    patch clean_import_url(@loaded_import), params: {
      import: {
        csv_update: {
          row_idx: 0,
          col_idx: 1,
          value: "new_merchant"
        }
      }
    }

    assert_response :success

    @loaded_import.reload
    assert_equal "new_merchant", @loaded_import.csv.table[0][1]
  end

  test "should get clean" do
    get clean_import_url(@loaded_import)
    assert_response :success
  end

  test "should get confirm if all values are valid" do
    get confirm_import_url(@loaded_import)
    assert_response :success
  end

  test "should redirect back to clean if data is invalid" do
    @empty_import.update! raw_csv_str: valid_csv_with_invalid_values

    get confirm_import_url(@empty_import)
    assert_equal "You have invalid data, please fix before continuing", flash[:alert]
    assert_redirected_to clean_import_path(@empty_import)
  end

  test "should confirm import" do
    patch confirm_import_url(@loaded_import)
    assert_redirected_to imports_path
    assert_equal "Import has started in the background", flash[:notice]
  end
end
