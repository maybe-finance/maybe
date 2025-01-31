require "test_helper"

class PlaidItemTest < ActiveSupport::TestCase
  include SyncableInterfaceTest

  setup do
    @plaid_item = @syncable = plaid_items(:one)
  end

  test "removes plaid item when destroyed" do
    @plaid_provider = mock
    @plaid_item.stubs(:plaid_provider_for).returns(@plaid_provider)
    @plaid_provider.expects(:remove_item).with(@plaid_item.access_token).once

    assert_difference "PlaidItem.count", -1 do
      @plaid_item.destroy
    end
  end

  test "if plaid item not found, silently continues with deletion" do
    @plaid_provider = mock
    @plaid_item.stubs(:plaid_provider_for).returns(@plaid_provider)
    @plaid_provider.expects(:remove_item).with(@plaid_item.access_token).raises(Plaid::ApiError.new("Item not found"))

    assert_difference "PlaidItem.count", -1 do
      @plaid_item.destroy
    end
  end

  test "safe_fetch_plaid_data calls provider with correct method" do
    @plaid_provider = mock
    @plaid_item.stubs(:plaid_provider_for).returns(@plaid_provider)
    @plaid_provider.expects(:send).with(:get_item_transactions, @plaid_item).returns("transaction_data")

    result = @plaid_item.send(:safe_fetch_plaid_data, :get_item_transactions)
    assert_equal "transaction_data", result
  end

  test "safe_fetch_plaid_data handles plaid api errors gracefully" do
    @plaid_provider = mock
    @plaid_item.stubs(:plaid_provider_for).returns(@plaid_provider)
    @plaid_provider.expects(:send).raises(Plaid::ApiError.new("API Error"))

    result = @plaid_item.send(:safe_fetch_plaid_data, :get_item_transactions)
    assert_nil result
  end
end
