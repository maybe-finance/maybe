require "test_helper"

class PlaidAccount::ImporterTest < ActiveSupport::TestCase
  setup do
    @mock_provider = mock("Provider::Plaid")
    @plaid_account = plaid_accounts(:one)
  end

  test "imports account data" do
    raw_payload = OpenStruct.new(
      account_id: "123",
      name: "Test Account",
      mask: "1234",
      type: "checking",
      subtype: "checking",
    )

    PlaidAccount::Importer.new(@plaid_account, raw_payload, plaid_provider: @mock_provider).import

    @plaid_account.reload

    assert_equal "123", @plaid_account.plaid_id
    assert_equal "Test Account", @plaid_account.name
    assert_equal "1234", @plaid_account.mask
    assert_equal "checking", @plaid_account.plaid_type
    assert_equal "checking", @plaid_account.plaid_subtype
  end
end
