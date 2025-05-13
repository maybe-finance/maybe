require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @family = Family.create!(name: "Test Family")
  end

  test "can create subscription without stripe details if trial" do
    subscription = Subscription.new(
      family: @family,
      status: :trialing,
    )

    assert_not subscription.valid?

    subscription.trial_ends_at = 14.days.from_now

    assert subscription.valid?
  end

  test "stripe details required for all statuses except trial" do
    subscription = Subscription.new(
      family: @family,
      status: :active,
    )

    assert_not subscription.valid?

    subscription.stripe_id = "test-stripe-id"

    assert subscription.valid?
  end
end
