require "test_helper"
require "ostruct"

class PlaidItem::ImporterTest < ActiveSupport::TestCase
  setup do
    @mock_provider = mock("Provider::Plaid")
    @plaid_item = plaid_items(:one)
  end

  test "imports item metadata" do
    mock_institution_id = "123"

    raw_item_payload = OpenStruct.new(
      item: OpenStruct.new(
        available_products: [],
        billed_products: %w[transactions investments liabilities],
        institution_id: mock_institution_id
      )
    )

    raw_institution_payload = OpenStruct.new(
      institution: OpenStruct.new(
        institution_id: mock_institution_id,
        url: "https://example.com",
        primary_color: "#000000"
      )
    )

    raw_accounts_payload = OpenStruct.new(
      accounts: [
        OpenStruct.new(
          account_id: "123",
          name: "Test Account",
          mask: "1234",
          type: "checking",
          subtype: "checking",
        )
      ]
    )

    @mock_provider.expects(:get_item).returns(raw_item_payload)
    @mock_provider.expects(:get_institution).with(mock_institution_id).returns(raw_institution_payload)
    @mock_provider.expects(:get_item_accounts).with(@plaid_item).returns(raw_accounts_payload)
    @mock_provider.expects(:get_item_transactions).with(@plaid_item).returns(OpenStruct.new(transactions: []))
    @mock_provider.expects(:get_item_investments).with(@plaid_item).returns(OpenStruct.new(investments: []))
    @mock_provider.expects(:get_item_liabilities).with(@plaid_item).returns(OpenStruct.new(liabilities: []))

    PlaidAccount::Importer.any_instance.expects(:import).times(raw_accounts_payload.accounts.count)

    PlaidItem::Importer.new(@plaid_item, plaid_provider: @mock_provider).import

    @plaid_item.reload

    assert_equal mock_institution_id, @plaid_item.institution_id
    assert_equal "https://example.com", @plaid_item.institution_url
    assert_equal "#000000", @plaid_item.institution_color
    assert_equal %w[transactions investments liabilities], @plaid_item.available_products
    assert_equal %w[transactions investments liabilities], @plaid_item.billed_products
    assert_not_nil @plaid_item.raw_payload
    assert_not_nil @plaid_item.raw_institution_payload
  end
end
