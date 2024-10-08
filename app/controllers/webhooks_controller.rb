class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :stripe ]
  skip_authentication

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError
      render json: { error: "Invalid payload" }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature" }, status: :bad_request
      return
    end

    case event.type
    when /^customer\.subscription\./
      handle_subscription_event(event)
    when "customer.created", "customer.updated", "customer.deleted"
      handle_customer_event(event)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    render json: { received: true }, status: :ok
  end

  private

    def handle_subscription_event(event)
      subscription = event.data.object
      family = Family.find_by(stripe_customer_id: subscription.customer)

      if family
        family.update(
          stripe_plan_id: subscription.plan.id,
          stripe_subscription_status: subscription.status
        )
      else
        Rails.logger.error "Family not found for Stripe customer ID: #{subscription.customer}"
      end
    end

    def handle_customer_event(event)
      customer = event.data.object
      family = Family.find_by(stripe_customer_id: customer.id)

      if family
        family.update(stripe_customer_id: customer.id)
      else
        Rails.logger.error "Family not found for Stripe customer ID: #{customer.id}"
      end
    end
end
