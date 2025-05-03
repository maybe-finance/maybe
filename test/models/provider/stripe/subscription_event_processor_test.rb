require "test_helper"

class Provider::Stripe::SubscriptionEventProcessorTest < ActiveSupport::TestCase
  setup do
    @stripe = Provider::Stripe.new(
      secret_key: ENV["STRIPE_SECRET_KEY"],
      webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"]
    )

    VCR.use_cassette("stripe/create_test_customer") do
      @test_email = "user_#{Time.current.to_i}@maybe.test"

      @test_clock = raw_client.v1.test_helpers.test_clocks.create(
        frozen_time: Time.current.to_i
      )

      # https://docs.stripe.com/testing?testing-method=payment-methods#test-code
      @test_customer = raw_client.v1.customers.create(
        email: @test_email,
        payment_method: "pm_card_visa",
        invoice_settings: {
          default_payment_method: "pm_card_visa"
        },
        test_clock: @test_clock.id
      )
    end
  end

  test "handles subscription event" do
    VCR.use_cassette("stripe/events/subscription/created") do
      family = Family.create!(
        name: "Test Subscribed Family",
        stripe_customer_id: @test_customer.id,
      )

      subscription = raw_client.v1.subscriptions.create(
        customer: @test_customer.id,
        items: [
          {
            price: ENV["STRIPE_MONTHLY_PRICE_ID"],
            quantity: 1
          }
        ],
      )

      family.start_subscription!(subscription.id)

      events = raw_client.v1.events.list(
        type: "customer.subscription.created"
      )

      subscription_create_event = events.data.find do |event|
        event.data.object.customer == @test_customer.id
      end

      processor = Provider::Stripe::SubscriptionEventProcessor.new(
        subscription_create_event
      )

      assert_equal "active", family.subscription.status
      assert_equal subscription.id, family.subscription.stripe_id
      assert_nil family.subscription.amount
      assert_nil family.subscription.currency
      assert_nil family.subscription.current_period_ends_at

      processor.process

      family.reload

      assert_equal "active", family.subscription.status
      assert_equal subscription.id, family.subscription.stripe_id
      assert_equal 9, family.subscription.amount
      assert_equal "USD", family.subscription.currency
      assert family.subscription.current_period_ends_at > 20.days.from_now
    end
  end

  private
    def raw_client
      @raw_client ||= Stripe::StripeClient.new(ENV["STRIPE_SECRET_KEY"])
    end
end
