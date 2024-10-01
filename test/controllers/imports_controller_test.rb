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

  test "creates import" do
    assert_difference "Import.count", 1 do
      post imports_url, params: {
        import: {
          type: "TransactionImport"
        }
      }
    end

    assert_redirected_to import_upload_url(Import.all.ordered.first)
  end

  test "publishes import" do
    import = imports(:transaction)

    TransactionImport.any_instance.expects(:publish_later).once

    post publish_import_url(import)

    assert_equal "Your import has started in the background.", flash[:notice]
    assert_redirected_to import_path(import)
  end

  test "destroys import" do
    import = imports(:transaction)

    assert_difference "Import.count", -1 do
      delete import_url(import)
    end

    assert_redirected_to imports_path
  end
end
