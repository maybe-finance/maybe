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
    account = accounts(:investment)
    holding = account.holdings.first
    exchange_rate = exchange_rates(:one)
    security_price = holding.security.prices.first
    account_balance = account.balances.create!(date: Date.current, balance: 1000, currency: "USD")

    with_self_hosting do
      perform_enqueued_jobs(only: DataCacheClearJob) do
        delete clear_cache_settings_hosting_url
      end
    end

    assert_redirected_to settings_hosting_url
    assert_equal I18n.t("settings.hostings.clear_cache.cache_cleared"), flash[:notice]

    assert_not ExchangeRate.exists?(exchange_rate.id)
    assert_not Security::Price.exists?(security_price.id)
    assert_not Account::Holding.exists?(holding.id)
    assert_not Account::Balance.exists?(account_balance.id)
  end

  test "can clear data only when admin" do
    with_self_hosting do
      sign_in users(:family_member)

      assert_no_enqueued_jobs do
        delete clear_cache_settings_hosting_url
      end

      assert_redirected_to settings_hosting_url
      assert_equal I18n.t("settings.hostings.not_authorized"), flash[:alert]
    end
  end
end
