require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  include ImportTestHelper

  setup do
    sign_in @user = users(:family_admin)
    @empty_import = imports(:empty_import)

    @loaded_import = @empty_import.dup
    @loaded_import.update! raw_file_str: valid_csv_str

    @completed_import = imports(:completed_import)
  end

  test "should get index" do
    get imports_url
    assert_response :success

    @user.family.imports.ordered.each do |import|
      assert_select "#" + dom_id(import), count: 1
    end
  end

  test "should destroy import" do
    assert_difference("Import.count", -1) do
      delete import_url(@empty_import)
    end

    assert_redirected_to imports_url
  end
end
