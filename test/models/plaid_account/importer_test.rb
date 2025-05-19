require "test_helper"

class PlaidAccount::ImporterTest < ActiveSupport::TestCase
  setup do
    @mock_provider = PlaidMock.new
    @plaid_account = plaid_accounts(:one)
    @plaid_item = @plaid_account.plaid_item

    @accounts_snapshot = PlaidItem::AccountsSnapshot.new(@plaid_item, plaid_provider: @mock_provider)
    @account_snapshot = @accounts_snapshot.get_account_data(@plaid_account.plaid_id)
  end

  test "imports account data" do
    PlaidAccount::Importer.new(@plaid_account, account_snapshot: @account_snapshot).import

    assert_equal @account_snapshot.account_data.account_id, @plaid_account.plaid_id
    assert_equal @account_snapshot.account_data.name, @plaid_account.name
    assert_equal @account_snapshot.account_data.mask, @plaid_account.mask
    assert_equal @account_snapshot.account_data.type, @plaid_account.plaid_type
    assert_equal @account_snapshot.account_data.subtype, @plaid_account.plaid_subtype

    # This account has transactions data
    assert_equal PlaidMock::TRANSACTIONS.count, @plaid_account.raw_transactions_payload["added"].count

    # This account does not have investment data
    assert_equal 0, @plaid_account.raw_investments_payload["holdings"].count
    assert_equal 0, @plaid_account.raw_investments_payload["securities"].count
    assert_equal 0, @plaid_account.raw_investments_payload["transactions"].count

    # This account is a credit card, so it should have liability data
    assert_equal @plaid_account.plaid_id, @plaid_account.raw_liabilities_payload["credit"]["account_id"]
    assert_nil @plaid_account.raw_liabilities_payload["mortgage"]
    assert_nil @plaid_account.raw_liabilities_payload["student"]
  end
end
