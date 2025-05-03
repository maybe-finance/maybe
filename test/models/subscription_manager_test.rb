require "test_helper"
require "ostruct"

class SubscriptionManagerTest < ActiveSupport::TestCase
  setup do
    @stripe_provider = mock
    Provider::Registry.stubs(:get_provider).with(:stripe).returns(@stripe_provider)

    @manager = SubscriptionManager.new(
      upgrade_url: "http://localhost:3000/subscription/upgrade",
      checkout_success_url: "http://localhost:3000/subscription/success",
      billing_url: "http://localhost:3000/settings/billing"
    )
  end

  test "validates checkout session result" do
    @stripe_provider.expects(:retrieve_checkout_session).with("test-session-id").returns(
      OpenStruct.new(
        subscription: "sub_123",
        status: "complete",
        payment_status: "paid"
      )
    )

    result = @manager.get_checkout_result("test-session-id")

    assert result.success?
    assert_equal "sub_123", result.subscription_id
  end
end
