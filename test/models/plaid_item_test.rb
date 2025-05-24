require "test_helper"

class PlaidItemTest < ActiveSupport::TestCase
  include SyncableInterfaceTest

  setup do
    @plaid_item = @syncable = plaid_items(:one)
    @plaid_provider = mock
    Provider::Registry.stubs(:plaid_provider_for_region).returns(@plaid_provider)
  end

  test "removes plaid item when destroyed" do
    @plaid_provider.expects(:remove_item).with(@plaid_item.access_token).once

    assert_difference "PlaidItem.count", -1 do
      @plaid_item.destroy
    end
  end
end
