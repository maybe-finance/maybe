require "test_helper"

class Family::SubscribeableTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
  end

  # We keep the status eventually consistent, but don't rely on it for guarding the app
  test "trial respects end date even if status is not yet updated" do
    @family.subscription.update!(trial_ends_at: 1.day.ago, status: "trialing")
    assert_not @family.trialing?
  end
end
