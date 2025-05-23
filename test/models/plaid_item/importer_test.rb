require "test_helper"
require "ostruct"

class PlaidItem::ImporterTest < ActiveSupport::TestCase
  setup do
    @mock_provider = PlaidMock.new
    @plaid_item = plaid_items(:one)
    @importer = PlaidItem::Importer.new(@plaid_item, plaid_provider: @mock_provider)
  end

  test "imports item metadata" do
    PlaidAccount::Importer.any_instance.expects(:import).times(PlaidMock::ACCOUNTS.count)

    PlaidItem::Importer.new(@plaid_item, plaid_provider: @mock_provider).import

    assert_equal PlaidMock::ITEM.institution_id, @plaid_item.institution_id
    assert_equal PlaidMock::ITEM.available_products, @plaid_item.available_products
    assert_equal PlaidMock::ITEM.billed_products, @plaid_item.billed_products

    assert_equal PlaidMock::ITEM.item_id, @plaid_item.raw_payload["item_id"]
    assert_equal PlaidMock::INSTITUTION.institution_id, @plaid_item.raw_institution_payload["institution_id"]
  end
end
