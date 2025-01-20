require "test_helper"

class PlaidItemTest < ActiveSupport::TestCase
  include SyncableInterfaceTest

  setup do
    @plaid_item = @syncable = plaid_items(:one)
  end

  test "removes plaid item when destroyed" do
    @plaid_provider = mock

    PlaidItem.stubs(:plaid_provider).returns(@plaid_provider)

    @plaid_provider.expects(:remove_item).with(@plaid_item.access_token).once

    assert_difference "PlaidItem.count", -1 do
      @plaid_item.destroy
    end
  end

  test "if plaid item not found, silently continues with deletion" do
    @plaid_provider = mock

    PlaidItem.stubs(:plaid_provider).returns(@plaid_provider)

    @plaid_provider.expects(:remove_item).with(@plaid_item.access_token).raises(Plaid::ApiError.new("Item not found"))

    assert_difference "PlaidItem.count", -1 do
      @plaid_item.destroy
    end
  end
end
