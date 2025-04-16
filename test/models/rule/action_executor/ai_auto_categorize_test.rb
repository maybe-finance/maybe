require "test_helper"

class Rule::ActionExecutor::AiAutoCategorizeTest < ActiveSupport::TestCase
  include EntriesTestHelper, ProviderTestHelper

  setup do
    @family = families(:dylan_family)
    @account = @family.accounts.create!(name: "Rule test", balance: 100, currency: "USD", accountable: Depository.new)
    @llm_provider = mock
    @rule = rules(:one)

    Rule.any_instance.stubs(:llm_provider).returns(@llm_provider)
  end

  test "auto-categorizes transactions" do
    txn1 = create_transaction(account: @account, name: "McDonalds").transaction
    txn2 = create_transaction(account: @account, name: "Amazon purchase").transaction
    txn3 = create_transaction(account: @account, name: "Netflix subscription").transaction

    test_category = @family.categories.create!(name: "Test category")

    provider_response = provider_success_response([
      AutoCategorization.new(transaction_id: txn1.id, category_name: test_category.name),
      AutoCategorization.new(transaction_id: txn2.id, category_name: test_category.name),
      AutoCategorization.new(transaction_id: txn3.id, category_name: nil)
    ])

    @llm_provider.expects(:auto_categorize).returns(provider_response).once

    # All 3 of newly created transactions are enrichable by category_id
    assert_equal 3, @account.transactions.reload.enrichable(:category_id).count

    Rule::ActionExecutor::AiAutoCategorize.new(@rule).execute(@account.transactions)

    assert_equal test_category, txn1.reload.category
    assert_equal test_category, txn2.reload.category
    assert_nil txn3.reload.category

    # After auto-categorization, all transactions are locked and no longer enrichable
    assert_equal 0, @account.transactions.reload.enrichable(:category_id).count
  end

  private
    AutoCategorization = Provider::LlmConcept::AutoCategorization
end
