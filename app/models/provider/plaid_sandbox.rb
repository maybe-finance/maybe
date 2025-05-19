class Provider::PlaidSandbox < Provider::Plaid
  attr_reader :client

  def initialize
    @client = create_client
    @region = :us
  end

  def create_public_token(institution_id: nil, products: nil, user: nil)
    client.sandbox_public_token_create(
      Plaid::SandboxPublicTokenCreateRequest.new(
        institution_id: institution_id || "ins_56", # Chase
        initial_products: products || [ "transactions", "investments", "liabilities" ],
        options: {
          # This is a custom user we created in Plaid Dashboard
          # See https://dashboard.plaid.com/developers/sandbox
          override_username: user || "custom_test"
        }
      )
    ).public_token
  end

  def fire_webhook(item, type: "TRANSACTIONS", code: "SYNC_UPDATES_AVAILABLE")
    client.sandbox_item_fire_webhook(
      Plaid::SandboxItemFireWebhookRequest.new(
        access_token: item.access_token,
        webhook_type: type,
        webhook_code: code,
      )
    )
  end

  private
    def create_client
      raise "Plaid sandbox is not supported in production" if Rails.env.production?

      api_client = Plaid::ApiClient.new(
        Rails.application.config.plaid
      )

      Plaid::PlaidApi.new(api_client)
    end
end
