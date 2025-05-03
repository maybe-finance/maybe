require "test_helper"
require "ostruct"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:empty)
    @family = @user.family
  end

  test "disabled for self hosted users" do
    Rails.application.config.app_mode.stubs(:self_hosted?).returns(true)
    post subscription_path
    assert_response :forbidden
  end

  # Trial subscriptions are managed internally and do NOT go through Stripe
  test "can create trial subscription" do
    @family.subscription.destroy
    @family.reload

    assert_difference "Subscription.count", 1 do
      post subscription_path
    end

    assert_redirected_to root_path
    assert_equal "Welcome to Maybe!", flash[:notice]
    assert_equal "trialing", @family.subscription.status
    assert_in_delta Subscription::TRIAL_DAYS.days.from_now, @family.subscription.trial_ends_at, 1.minute
  end

  test "users who have already trialed cannot create a new subscription" do
    @family.start_trial_subscription!

    assert_no_difference "Subscription.count" do
      post subscription_path
    end

    assert_redirected_to root_path
    assert_equal "You have already started or completed a trial. Please upgrade to continue.", flash[:alert]
  end

  test "creates active subscription on checkout success" do
    SubscriptionManager.any_instance.expects(:get_checkout_result).with("test-session-id").returns(
      OpenStruct.new(
        success?: true,
        subscription_id: "test-subscription-id"
      )
    )

    get success_subscription_url(session_id: "test-session-id")

    assert @family.subscription.active?
    assert_equal "Welcome to Maybe!  Your subscription has been created.", flash[:notice]
  end
end
