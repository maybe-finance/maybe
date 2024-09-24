require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "gets index" do
    get imports_url

    assert_response :success

    @user.family.imports.ordered.each do |import|
      assert_select "#" + dom_id(import), count: 1
    end
  end

  test "gets new" do
    get new_import_url

    assert_response :success

    assert_select "turbo-frame#modal"
  end

  test "creates import with template" do
    assert_difference "Import.count", 1 do
      post imports_url, params: {
        import: {
          template: "transaction"
        }
      }
    end

    assert_redirected_to import_url(Import.all.ordered.first)
  end

  test "can delete import if not completed" do
    import = imports(:pending)

    assert_difference "Import.count", -1 do
      delete import_url(import)
    end

    assert_equal "Import deleted.", flash[:notice]
    assert_redirected_to imports_url
  end

  test "cannot delete import if completed" do
    import = imports(:completed)

    assert_difference "Import.count", 0 do
      delete import_url(import)
    end

    assert_equal "You cannot delete completed imports.", flash[:alert]
    assert_redirected_to imports_url
  end
end
