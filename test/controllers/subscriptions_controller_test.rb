require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "can start trial" do
    @user.update!(onboarded_at: nil)
    @user.family.update!(trial_started_at: nil, stripe_subscription_status: "incomplete")

    assert_nil @user.onboarded_at
    assert_nil @user.family.trial_started_at

    post start_trial_subscription_path
    assert_redirected_to root_path
    assert_equal "Welcome to Maybe!", flash[:notice]

    assert @user.reload.onboarded?
    assert @user.family.reload.trial_started_at.present?
  end

  test "if user re-enters onboarding, don't restart trial" do
    onboard_time = 1.day.ago
    trial_start_time = 1.day.ago

    @user.update!(onboarded_at: onboard_time)
    @user.family.update!(trial_started_at: trial_start_time, stripe_subscription_status: "incomplete")

    post start_trial_subscription_path
    assert_redirected_to root_path

    assert @user.reload.family.trial_started_at < Date.current
  end

  test "redirects to settings if self hosting" do
    Rails.application.config.app_mode.stubs(:self_hosted?).returns(true)
    get subscription_path
    assert_response :forbidden
  end
end
