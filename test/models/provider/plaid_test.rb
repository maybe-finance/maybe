require "test_helper"

class Provider::PlaidTest < ActiveSupport::TestCase
  setup do
    @provider = Provider::Plaid.new(Rails.application.config.plaid, :us)
  end

  test "creates link token with only primary product" do
    request = Plaid::LinkTokenCreateRequest.new({
      user: { client_user_id: "123" },
      client_name: "Maybe Finance",
      products: ["transactions"],
      country_codes: ["US", "CA"],
      language: "en",
      webhook: "https://example.com/webhook",
      redirect_uri: "https://example.com/callback",
      transactions: { days_requested: Provider::Plaid::MAX_HISTORY_DAYS }
    })

    @provider.client.expects(:link_token_create)
      .with { |req| req.products == ["transactions"] && !req.respond_to?(:additional_consented_products) }
      .returns(OpenStruct.new(link_token: "test-token"))

    response = @provider.get_link_token(
      user_id: "123",
      webhooks_url: "https://example.com/webhook",
      redirect_url: "https://example.com/callback"
    )

    assert_equal "test-token", response.link_token
  end

  test "creates link token with investments product for investment accounts" do
    request = Plaid::LinkTokenCreateRequest.new({
      user: { client_user_id: "123" },
      client_name: "Maybe Finance",
      products: ["investments"],
      country_codes: ["US", "CA"],
      language: "en",
      webhook: "https://example.com/webhook",
      redirect_uri: "https://example.com/callback",
      transactions: { days_requested: Provider::Plaid::MAX_HISTORY_DAYS }
    })

    @provider.client.expects(:link_token_create)
      .with { |req| req.products == ["investments"] && !req.respond_to?(:additional_consented_products) }
      .returns(OpenStruct.new(link_token: "test-token"))

    response = @provider.get_link_token(
      user_id: "123",
      webhooks_url: "https://example.com/webhook",
      redirect_url: "https://example.com/callback",
      accountable_type: "Investment"
    )

    assert_equal "test-token", response.link_token
  end
end
