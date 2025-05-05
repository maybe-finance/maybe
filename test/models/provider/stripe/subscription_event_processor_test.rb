require "test_helper"

class Provider::Stripe::SubscriptionEventProcessorTest < ActiveSupport::TestCase
  setup do
    @stripe = Provider::Stripe.new(
      secret_key: ENV["STRIPE_SECRET_KEY"],
      webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"]
    )

    @test_customer_email = "user_#{Time.current.to_i}@maybe.test"
  end

  test "handles subscription event" do
    VCR.use_cassette("stripe/events/subscription") do
      customer = create_test_customer

      family = Family.create!(
        name: "Test Subscribed Family",
        stripe_customer_id: customer.id,
      )

      subscription = raw_client.v1.subscriptions.create(
        customer: customer.id,
        items: [
          {
            price: ENV["STRIPE_MONTHLY_PRICE_ID"],
            quantity: 1
          }
        ],
      )

      family.start_subscription!(subscription.id)

      sleep 10

      events = raw_client.v1.events.list(
        type: "customer.subscription.created",
        created: { gt: 1.minute.ago.to_i }
      )

      subscription_create_event = events.data.find do |event|
        event.data.object.customer == customer.id
      end

      processor = Provider::Stripe::SubscriptionEventProcessor.new(
        event: subscription_create_event,
        client: raw_client
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

    def create_test_customer
      # https://docs.stripe.com/testing?testing-method=payment-methods#test-code
      raw_client.v1.customers.create(
        email: @test_customer_email,
        payment_method: "pm_card_visa",
        invoice_settings: {
          default_payment_method: "pm_card_visa"
        },
      )
    end
end
