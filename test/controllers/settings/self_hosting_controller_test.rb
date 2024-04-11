require "test_helper"

class Settings::SelfHostingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end
  test "should get edit when self hosting is enabled" do
    ApplicationController.any_instance.stubs(:self_hosted?).returns(true)
    get edit_settings_self_hosting_url
    assert_response :success
  end

  test "cannot edit when self hosting is disabled" do
    ApplicationController.any_instance.stubs(:self_hosted?).returns(false)

    get edit_settings_self_hosting_url
    assert_redirected_to edit_settings_url
  end

  test "can update settings when self hosting is enabled" do
    NEW_RENDER_DEPLOY_HOOK = "https://api.render.com/deploy/srv-"
    ApplicationController.any_instance.stubs(:self_hosted?).returns(true)

    assert_nil Setting.render_deploy_hook
    patch settings_self_hosting_url, params: { setting: { render_deploy_hook: NEW_RENDER_DEPLOY_HOOK } }
    assert_equal NEW_RENDER_DEPLOY_HOOK, Setting.render_deploy_hook
  end

  test "cannot update dynamic settings when self hosting is disabled" do
    ApplicationController.any_instance.stubs(:self_hosted?).returns(false)

    patch settings_self_hosting_url, params: { setting: { render_deploy_hook: "https://example.com" } }

    assert_response :forbidden
  end
end
