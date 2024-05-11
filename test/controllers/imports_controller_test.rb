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

    assert_redirected_to import_clean_path(import)
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
end
