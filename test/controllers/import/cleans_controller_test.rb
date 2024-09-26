require "test_helper"

class Import::CleansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "shows if configured" do
    import = imports(:transaction)

    TransactionImport.any_instance.stubs(:configured?).returns(true)

    get import_clean_path(import)
    assert_response :success
  end

  test "redirects if not configured" do
    import = imports(:transaction)

    TransactionImport.any_instance.stubs(:configured?).returns(false)

    get import_clean_path(import)
    assert_redirected_to import_configuration_path(import)
  end
end
