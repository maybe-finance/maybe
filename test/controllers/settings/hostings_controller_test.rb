require "test_helper"

class Settings::HostingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "cannot edit when self hosting is disabled" do
    assert_raises(RuntimeError, "Settings not available on non-self-hosted instance") do
      get settings_hosting_url
    end

    assert_raises(RuntimeError, "Settings not available on non-self-hosted instance") do
      patch settings_hosting_url, params: { setting: { render_deploy_hook: "https://example.com" } }
    end
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

  test "can choose auto upgrades mode with a deploy hook" do
    with_self_hosting do
      NEW_RENDER_DEPLOY_HOOK = "https://api.render.com/deploy/srv-abc123"
      assert_nil Setting.render_deploy_hook

      patch settings_hosting_url, params: { setting: { render_deploy_hook: NEW_RENDER_DEPLOY_HOOK, upgrades_setting: "release" } }

      assert_equal "auto", Setting.upgrades_mode
      assert_equal "release", Setting.upgrades_target
      assert_equal NEW_RENDER_DEPLOY_HOOK, Setting.render_deploy_hook
    end
  end

  test "can clear data cache when self hosting is enabled" do
    with_self_hosting do
      assert_enqueued_with(job: DataCacheClearJob) do
        delete clear_cache_settings_hosting_url
      end

      assert_redirected_to settings_hosting_url
      assert_equal I18n.t("settings.hostings.clear_cache.cache_cleared"), flash[:notice]
    end
  end
end
