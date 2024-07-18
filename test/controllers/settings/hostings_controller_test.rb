require "test_helper"

class Settings::HostingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "cannot edit when self hosting is disabled" do
    get settings_hosting_url
    assert :not_found

    patch settings_hosting_url, params: { setting: { render_deploy_hook: "https://example.com" } }
    assert :not_found
  end

  test "should get edit when self hosting is enabled" do
    with_self_hosting do
      get settings_hosting_url
      assert_response :success
    end
  end

  test "can update settings when self hosting is enabled" do
    with_self_hosting do
      NEW_RENDER_DEPLOY_HOOK = "https://api.render.com/deploy/srv-abc123"
      assert_nil Setting.render_deploy_hook

      patch settings_hosting_url, params: { setting: { render_deploy_hook: NEW_RENDER_DEPLOY_HOOK } }

      assert_equal NEW_RENDER_DEPLOY_HOOK, Setting.render_deploy_hook
    end
  end

  test "cannot set auto upgrades mode without a deploy hook" do
    with_self_hosting do
      patch settings_hosting_url, params: { setting: { upgrades_mode: "auto" } }
      assert_response :unprocessable_entity
    end
  end

  test "can choose auto upgrades mode with a deploy hook" do
    with_self_hosting do
      NEW_RENDER_DEPLOY_HOOK = "https://api.render.com/deploy/srv-abc123"
      assert_nil Setting.render_deploy_hook

      patch settings_hosting_url, params: { setting: { render_deploy_hook: NEW_RENDER_DEPLOY_HOOK, upgrades_mode: "release" } }

      assert_equal "auto", Setting.upgrades_mode
      assert_equal "release", Setting.upgrades_target
      assert_equal NEW_RENDER_DEPLOY_HOOK, Setting.render_deploy_hook
    end
  end

  test " #send_test_email if smtp settings are populated try to send an email and redirect with notice" do
    with_self_hosting do
      Setting.stubs(:smtp_settings_populated?).returns(true)

      test_email_mock = mock
      test_email_mock.expects(:deliver_now)

      mailer_mock = mock
      mailer_mock.expects(:test_email).returns(test_email_mock)

      NotificationMailer.expects(:with).with(user: users(:family_admin)).returns(mailer_mock)

      post send_test_email_settings_hosting_path
      assert_response :found
      assert controller.flash[:notice].present?
    end
  end

  test "#send_test_email with one blank smtp setting" do
    with_self_hosting do
      Setting.stubs(:smtp_settings_populated?).returns(false)
      NotificationMailer.expects(:with).never

      post send_test_email_settings_hosting_path
      assert_response :unprocessable_entity
      assert controller.flash[:alert].present?
    end
  end

  test "#send_test_email when sending the email raise an error" do
    with_self_hosting do
      Setting.stubs(:smtp_settings_populated?).returns(true)
      NotificationMailer.stubs(:with).raises(StandardError)

      post send_test_email_settings_hosting_path
      assert_response :unprocessable_entity
      assert controller.flash[:alert].present?
    end
  end
end
