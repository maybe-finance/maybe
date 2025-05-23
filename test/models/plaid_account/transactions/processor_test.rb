require "test_helper"

class PlaidAccount::Transactions::ProcessorTest < ActiveSupport::TestCase
  setup do
    @plaid_account = plaid_accounts(:one)
  end

  test "processes added and modified plaid transactions" do
    added_transactions = [ { "transaction_id" => "123" } ]
    modified_transactions = [ { "transaction_id" => "456" } ]

    @plaid_account.update!(raw_transactions_payload: {
      added: added_transactions,
      modified: modified_transactions,
      removed: []
    })

    mock_processor = mock("PlaidEntry::Processor")
    category_matcher_mock = mock("PlaidAccount::Transactions::CategoryMatcher")

    PlaidAccount::Transactions::CategoryMatcher.stubs(:new).returns(category_matcher_mock)
    PlaidEntry::Processor.expects(:new)
                         .with(added_transactions.first, plaid_account: @plaid_account, category_matcher: category_matcher_mock)
                         .returns(mock_processor)
                         .once

    PlaidEntry::Processor.expects(:new)
                         .with(modified_transactions.first, plaid_account: @plaid_account, category_matcher: category_matcher_mock)
                         .returns(mock_processor)
                         .once

    mock_processor.expects(:process).twice

    processor = PlaidAccount::Transactions::Processor.new(@plaid_account)
    processor.process
  end

  test "removes transactions no longer in plaid" do
    destroyable_transaction_id = "destroy_me"
    @plaid_account.account.entries.create!(
      plaid_id: destroyable_transaction_id,
      date: Date.current,
      amount: 100,
      name: "Destroy me",
      currency: "USD",
      entryable: Transaction.new
    )

    @plaid_account.update!(raw_transactions_payload: {
      added: [],
      modified: [],
      removed: [ { "transaction_id" => destroyable_transaction_id } ]
    })

    processor = PlaidAccount::Transactions::Processor.new(@plaid_account)

    assert_difference [ "Entry.count", "Transaction.count" ], -1 do
      processor.process
    end

    assert_nil Entry.find_by(plaid_id: destroyable_transaction_id)
  end
end
