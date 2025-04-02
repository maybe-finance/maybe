require "test_helper"

class RuleTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @family = families(:empty)
    @account = @family.accounts.create!(name: "Rule test", balance: 1000, currency: "USD", accountable: Depository.new)
    @shopping_category = @family.categories.create!(name: "Shopping")
  end

  test "basic rule" do
    transaction_entry = create_transaction(date: Date.current, account: @account, merchant: merchants(:amazon))

    rule = Rule.create!(
      family: @family,
      resource_type: "transaction",
      effective_date: 1.day.ago.to_date,
      conditions: [ Rule::Condition.new(condition_type: "transaction_merchant", operator: "=", value: "Amazon") ],
      actions: [ Rule::Action.new(action_type: "set_transaction_category", value: @shopping_category.id) ]
    )

    rule.apply

    transaction_entry.reload

    assert_equal @shopping_category, transaction_entry.account_transaction.category
  end

  test "compound rule" do
    transaction_entry1 = create_transaction(date: Date.current, amount: 50, account: @account, merchant: merchants(:amazon))
    transaction_entry2 = create_transaction(date: Date.current, amount: 100, account: @account, merchant: merchants(:amazon))

    # Assign "Groceries" to transactions with a merchant of "Whole Foods" and an amount greater than $60
    rule = Rule.create!(
      family: @family,
      resource_type: "transaction",
      effective_date: 1.day.ago.to_date,
      conditions: [
        Rule::Condition.new(condition_type: "compound", operator: "and", sub_conditions: [
          Rule::Condition.new(condition_type: "transaction_merchant", operator: "=", value: "Amazon"),
          Rule::Condition.new(condition_type: "transaction_amount", operator: ">", value: 60)
        ])
      ],
      actions: [ Rule::Action.new(action_type: "set_transaction_category", value: @shopping_category.id) ]
    )

    rule.apply

    transaction_entry1.reload
    transaction_entry2.reload

    assert_nil transaction_entry1.account_transaction.category
    assert_equal @shopping_category, transaction_entry2.account_transaction.category
  end
end
