require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @imports = @user.family.imports.ordered.to_a
  end

  test "should get index" do
    get imports_url
    assert_response :success
  end

  test "should get new" do
    get new_import_url
    assert_response :success
  end

  test "should create import" do
    assert_difference("Import.count") do
      post imports_url, params: { import: { account_id: @imports.first.account_id, column_mappings: @imports.first.column_mappings } }
    end
  end

  test "should get edit" do
    get edit_import_url(@imports.first)
    assert_response :success
  end

  test "should destroy import" do
    assert_difference("Import.count", -1) do
      delete import_url(@imports.first)
    end

    assert_redirected_to imports_url
  end
end
