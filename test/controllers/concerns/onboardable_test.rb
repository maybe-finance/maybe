require "test_helper"

class OnboardableTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:empty)
    @user.family.subscription.destroy
  end

  test "must complete onboarding before any other action" do
    @user.update!(onboarded_at: nil)

    get root_path
    assert_redirected_to onboarding_path
  end

  test "must have subscription to visit dashboard" do
    @user.update!(onboarded_at: 1.day.ago)

    get root_path
    assert_redirected_to trial_onboarding_path
  end

  test "onboarded subscribed user can visit dashboard" do
    @user.update!(onboarded_at: 1.day.ago)
    @user.family.start_trial_subscription!

    get root_path
    assert_response :success
  end
end
