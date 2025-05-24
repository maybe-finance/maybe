require "test_helper"

class PlaidAccount::ImporterTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)
    @mock_account_snapshot = mock
  end

  test "imports account data" do
    account_data = OpenStruct.new(
      account_id: "acc_1",
      name: "Test Account",
      mask: "1234",
    )

    transactions_data = OpenStruct.new(
      added: [],
      modified: [],
      removed: [],
    )

    investments_data = OpenStruct.new(
      holdings: [],
      transactions: [],
      securities: [],
    )

    liabilities_data = OpenStruct.new(
      credit: [],
      mortgage: [],
      student: [],
    )

    @mock_account_snapshot.expects(:account_data).returns(account_data).at_least_once
    @mock_account_snapshot.expects(:transactions_data).returns(transactions_data).at_least_once
    @mock_account_snapshot.expects(:investments_data).returns(investments_data).at_least_once
    @mock_account_snapshot.expects(:liabilities_data).returns(liabilities_data).at_least_once

    @plaid_account.expects(:upsert_plaid_snapshot!).with(account_data)
    @plaid_account.expects(:upsert_plaid_transactions_snapshot!).with(transactions_data)
    @plaid_account.expects(:upsert_plaid_investments_snapshot!).with(investments_data)
    @plaid_account.expects(:upsert_plaid_liabilities_snapshot!).with(liabilities_data)

    PlaidAccount::Importer.new(@plaid_account, account_snapshot: @mock_account_snapshot).import
  end
end
