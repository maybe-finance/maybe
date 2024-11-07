class Provider::Plaid
  attr_reader :client

  class << self
    def validate_webhook!(verification_header)
      decoded_header = JWT.decode(
        verification_header, nil, false,
        { algorithm: "ES256", verify_expiration: false }
      ).first

      key_id = decoded_header["kid"]

      jwk = client.webhook_verification_key_get(
        Plaid::WebhookVerificationKeyGetRequest.new(key_id: key_id)
      ).key

      public_key = JWT::JWK.import(jwk).public_key
      decoded_token = JWT.decode(
        verification_header, public_key, true,
        { algorithm: "ES256" }
      )

      payload = decoded_token.first

      issued_at = Time.at(payload["iat"])
      raise JWT::VerificationError, "Webhook is too old" if Time.now - issued_at > 5.minutes

      expected_hash = payload["request_body_sha256"]
      actual_hash = Digest::SHA256.hexdigest(webhook_body)
      raise JWT::VerificationError, "Invalid webhook body hash" unless ActiveSupport::SecurityUtils.secure_compare(expected_hash, actual_hash)
    end

    def client
      api_client = Plaid::ApiClient.new(
        Rails.application.config.plaid
      )

      Plaid::PlaidApi.new(api_client)
    end
  end

  def initialize
    @client = self.class.client
  end

  def get_link_token(user_id:, country:, webhooks_url:)
    request = Plaid::LinkTokenCreateRequest.new({
      user: { client_user_id: user_id },
      client_name: "Maybe",
      products: %w[transactions],
      country_codes: [ country ],
      language: "en",
      webhook: webhooks_url
    })

    client.link_token_create(request)
  end

  def exchange_public_token(token)
    request = Plaid::ItemPublicTokenExchangeRequest.new(
      public_token: token
    )

    client.item_public_token_exchange(request)
  end

  def remove_item(access_token)
    request = Plaid::ItemRemoveRequest.new(access_token: access_token)
    client.item_remove(request)
  end
end
