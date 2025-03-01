require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "redirects to settings if self hosting" do
    Rails.application.config.app_mode.stubs(:self_hosted?).returns(true)
    get subscription_path
    assert_redirected_to root_path
    assert_equal I18n.t("subscriptions.self_hosted_alert"), flash[:alert]
  end
end
