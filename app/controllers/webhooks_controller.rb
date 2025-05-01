class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_authentication

  def plaid
    webhook_body = request.body.read
    plaid_verification_header = request.headers["Plaid-Verification"]

    client = Provider::Plaid.new(Rails.application.config.plaid, region: :us)

    client.validate_webhook!(plaid_verification_header, webhook_body)
    client.process_webhook(webhook_body)

    render json: { received: true }, status: :ok
  rescue => error
    Sentry.capture_exception(error)
    render json: { error: "Invalid webhook: #{error.message}" }, status: :bad_request
  end

  def plaid_eu
    webhook_body = request.body.read
    plaid_verification_header = request.headers["Plaid-Verification"]

    client = Provider::Plaid.new(Rails.application.config.plaid_eu, region: :eu)

    client.validate_webhook!(plaid_verification_header, webhook_body)
    client.process_webhook(webhook_body)

    render json: { received: true }, status: :ok
  rescue => error
    Sentry.capture_exception(error)
    render json: { error: "Invalid webhook: #{error.message}" }, status: :bad_request
  end

  def stripe
    stripe_provider = Provider::Registry.get_provider(:stripe)

    begin
      webhook_body = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      stripe_provider.process_webhook_later(webhook_body, sig_header)

      head :ok
    rescue JSON::ParserError => error
      Sentry.capture_exception(error)
      head :bad_request
    rescue Stripe::SignatureVerificationError => error
      Sentry.capture_exception(error)
      head :bad_request
    end
  end
end
