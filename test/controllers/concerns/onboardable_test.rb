require "test_helper"

class OnboardableTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:empty)
  end

  test "must complete onboarding before any other action" do
    @user.update!(onboarded_at: nil)

    get root_path
    assert_redirected_to onboarding_path

    @user.family.update!(trial_started_at: 1.day.ago, stripe_subscription_status: "active")

    get root_path
    assert_redirected_to onboarding_path
  end

  test "must subscribe if onboarding complete and no trial or subscription is active" do
    @user.update!(onboarded_at: 1.day.ago)
    @user.family.update!(trial_started_at: nil, stripe_subscription_status: "incomplete")

    get root_path
    assert_redirected_to upgrade_subscription_path
  end

  test "onboarded trial user can visit dashboard" do
    @user.update!(onboarded_at: 1.day.ago)
    @user.family.update!(trial_started_at: 1.day.ago, stripe_subscription_status: "incomplete")

    get root_path
    assert_response :success
  end

  test "onboarded subscribed user can visit dashboard" do
    @user.update!(onboarded_at: 1.day.ago)
    @user.family.update!(stripe_subscription_status: "active")

    get root_path
    assert_response :success
  end
end
