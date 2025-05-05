require "test_helper"

class Provider::StripeTest < ActiveSupport::TestCase
  setup do
    @stripe = Provider::Stripe.new(
      secret_key: ENV["STRIPE_SECRET_KEY"] || "foo",
      webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"] || "bar"
    )
  end

  test "creates checkout session" do
    test_email = "test@example.com"

    test_success_url = "http://localhost:3000/subscription/success?session_id={CHECKOUT_SESSION_ID}"
    test_cancel_url = "http://localhost:3000/subscription/upgrade"

    VCR.use_cassette("stripe/create_checkout_session") do
      session = @stripe.create_checkout_session(
        plan: "monthly",
        family_id: 1,
        family_email: test_email,
        success_url: test_success_url,
        cancel_url: test_cancel_url
      )

      assert_match /https:\/\/checkout.stripe.com\/c\/pay\/cs_test_.*/, session.url
      assert_match /cus_.*/, session.customer_id
    end
  end

  # To re-run VCR for this test:
  # 1. Complete a checkout session locally in the UI
  # 2. Find the session ID, replace below
  # 3. Re-run VCR, make sure ENV vars are in test environment
  test "validates checkout session and returns subscription ID" do
    test_session_id = "cs_test_b1RD8r6DAkSA8vrQ3grBC2QVgR5zUJ7QQFuVHZkcKoSYaEOQgCMPMOCOM5" # must exist in test Dashboard

    VCR.use_cassette("stripe/checkout_session") do
      result = @stripe.get_checkout_result(test_session_id)

      assert result.success?
      assert_match /sub_.*/, result.subscription_id
    end
  end
end
