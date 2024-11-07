class Provider::Plaid
  attr_reader :client

  def initialize
    @client = create_client
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

  private
    def create_client
      api_client = Plaid::ApiClient.new(
        Rails.application.config.plaid
      )

      Plaid::PlaidApi.new(api_client)
    end
end
