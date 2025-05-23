require "test_helper"

class Provider::PlaidTest < ActiveSupport::TestCase
  setup do
    # Do not change, this is whitelisted in the Plaid Dashboard for local dev
    @redirect_url = "http://localhost:3000/accounts"

    # A specialization of Plaid client with sandbox-only extensions
    @plaid = Provider::PlaidSandbox.new
  end

  test "gets link token" do
    VCR.use_cassette("plaid/link_token") do
      link_token = @plaid.get_link_token(
        user_id: "test-user-id",
        webhooks_url: "https://example.com/webhooks",
        redirect_url: @redirect_url
      )

      assert_match /link-sandbox-.*/, link_token.link_token
    end
  end

  test "exchanges public token" do
    VCR.use_cassette("plaid/exchange_public_token") do
      public_token = @plaid.create_public_token
      exchange_response = @plaid.exchange_public_token(public_token)

      assert_match /access-sandbox-.*/, exchange_response.access_token
    end
  end

  test "gets item" do
    VCR.use_cassette("plaid/get_item") do
      access_token = get_access_token
      item = @plaid.get_item(access_token).item

      assert_equal "ins_109508", item.institution_id
      assert_equal "First Platypus Bank", item.institution_name
    end
  end

  test "gets item accounts" do
    VCR.use_cassette("plaid/get_item_accounts") do
      access_token = get_access_token
      accounts_response = @plaid.get_item_accounts(access_token)

      assert_equal 4, accounts_response.accounts.size
    end
  end

  test "gets item investments" do
    VCR.use_cassette("plaid/get_item_investments") do
      access_token = get_access_token
      investments_response = @plaid.get_item_investments(access_token)

      assert_equal 3, investments_response.holdings.size
      assert_equal 4, investments_response.transactions.size
    end
  end

  test "gets item liabilities" do
    VCR.use_cassette("plaid/get_item_liabilities") do
      access_token = get_access_token
      liabilities_response = @plaid.get_item_liabilities(access_token)

      assert liabilities_response.credit.count > 0
      assert liabilities_response.student.count > 0
    end
  end

  private
    def get_access_token
      VCR.use_cassette("plaid/access_token") do
        public_token = @plaid.create_public_token
        exchange_response = @plaid.exchange_public_token(public_token)
        exchange_response.access_token
      end
    end
end
