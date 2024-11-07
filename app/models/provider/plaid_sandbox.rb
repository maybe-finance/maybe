class Provider::PlaidSandbox < Provider::Plaid
  attr_reader :client

  def initialize
    @client = create_client
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
