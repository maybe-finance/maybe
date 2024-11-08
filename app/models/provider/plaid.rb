class Provider::Plaid
  attr_reader :client

  class << self
    def validate_webhook!(verification_header, raw_body)
      jwks_loader = ->(options) do
        key_id = options[:kid]

        # TODO: Cache this
        # @see https://plaid.com/docs/api/webhooks/webhook-verification/#caching-and-key-rotation
        jwk_response = client.webhook_verification_key_get(
          Plaid::WebhookVerificationKeyGetRequest.new(key_id: key_id)
        )

        jwks = JWT::JWK::Set.new([ jwk_response.key.to_hash ])

        jwks.filter! { |key| key[:use] == "sig" }
        jwks
      end

      payload, _header = JWT.decode(
        verification_header, nil, true,
        {
          algorithms: [ "ES256" ],
          jwks: jwks_loader,
          verify_expiration: false
        }
      )

      issued_at = Time.at(payload["iat"])
      raise JWT::VerificationError, "Webhook is too old" if Time.now - issued_at > 5.minutes

      expected_hash = payload["request_body_sha256"]
      actual_hash = Digest::SHA256.hexdigest(raw_body)
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

  def get_item_accounts(item)
    request = Plaid::AccountsGetRequest.new(access_token: item.access_token)
    client.accounts_get(request)
  end
end
