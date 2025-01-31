require "test_helper"

class Provider::PlaidTest < ActiveSupport::TestCase
  setup do
    @provider = Provider::Plaid.new
  end

  test "get_link_token uses supported country code" do
    mock_client = mock()
    @provider.stubs(:client).returns(mock_client)

    mock_client.expects(:link_token_create).with(
      has_entries(
        country_codes: ["CA"],
        client_name: "Maybe Finance",
        language: "en"
      )
    ).returns(OpenStruct.new(link_token: "test_token"))

    response = @provider.get_link_token(
      user_id: "123",
      webhooks_url: "https://example.com/webhook",
      redirect_url: "https://example.com/redirect",
      country_code: "CA"
    )

    assert_equal "test_token", response.link_token
  end

  test "get_link_token defaults to US for unsupported country code" do
    mock_client = mock()
    @provider.stubs(:client).returns(mock_client)

    mock_client.expects(:link_token_create).with(
      has_entries(
        country_codes: ["US"]
      )
    ).returns(OpenStruct.new(link_token: "test_token"))

    response = @provider.get_link_token(
      user_id: "123",
      webhooks_url: "https://example.com/webhook",
      redirect_url: "https://example.com/redirect",
      country_code: "XX"
    )

    assert_equal "test_token", response.link_token
  end

  test "get_link_token handles nil country code" do
    mock_client = mock()
    @provider.stubs(:client).returns(mock_client)

    mock_client.expects(:link_token_create).with(
      has_entries(
        country_codes: ["US"]
      )
    ).returns(OpenStruct.new(link_token: "test_token"))

    response = @provider.get_link_token(
      user_id: "123",
      webhooks_url: "https://example.com/webhook",
      redirect_url: "https://example.com/redirect",
      country_code: nil
    )

    assert_equal "test_token", response.link_token
  end

  test "get_primary_product returns correct product for accountable type" do
    assert_equal "investments", @provider.send(:get_primary_product, "Investment")
    assert_equal "liabilities", @provider.send(:get_primary_product, "CreditCard")
    assert_equal "liabilities", @provider.send(:get_primary_product, "Loan")
    assert_equal "transactions", @provider.send(:get_primary_product, "Depository")
    assert_equal "transactions", @provider.send(:get_primary_product, nil)
  end
end
