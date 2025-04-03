require "test_helper"

class Rule::ConditionTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @family = families(:empty)
    @transaction_rule = @family.rules.create!(resource_type: "transaction")
    @account = @family.accounts.create!(name: "Rule test", balance: 1000, currency: "USD", accountable: Depository.new)

    @grocery_category = @family.categories.create!(name: "Grocery")
    @whole_foods_merchant = @family.merchants.create!(name: "Whole Foods", type: "FamilyMerchant")

    # Some sample transactions to work with
    create_transaction(date: Date.current, account: @account, amount: 100, name: "Rule test transaction1", merchant: @whole_foods_merchant)
    create_transaction(date: Date.current, account: @account, amount: -200, name: "Rule test transaction2")
    create_transaction(date: 1.day.ago.to_date, account: @account, amount: 50, name: "Rule test transaction3")
    create_transaction(date: 1.year.ago.to_date, account: @account, amount: 10, name: "Rule test transaction4", merchant: @whole_foods_merchant)
    create_transaction(date: 1.year.ago.to_date, account: @account, amount: 1000, name: "Rule test transaction5")

    @rule_scope = @account.transactions
  end

  test "applies transaction_name condition" do
    condition = Rule::Condition.new(
      rule: @transaction_rule,
      condition_type: "transaction_name",
      operator: "=",
      value: "Rule test transaction1"
    )

    assert_equal 5, @rule_scope.count

    filtered = condition.apply(@rule_scope)

    assert_equal 1, filtered.count
  end

  test "applies transaction_amount condition" do
    condition = Rule::Condition.new(
      rule: @transaction_rule,
      condition_type: "transaction_amount",
      operator: ">",
      value: "50"
    )

    filtered = condition.apply(@rule_scope)
    assert_equal 2, filtered.count
  end

  test "applies transaction_merchant condition" do
    condition = Rule::Condition.new(
      rule: @transaction_rule,
      condition_type: "transaction_merchant",
      operator: "=",
      value: "Whole Foods"
    )

    filtered = condition.apply(@rule_scope)
    assert_equal 2, filtered.count
  end

  test "applies compound and condition" do
    parent_condition = Rule::Condition.new(
      rule: @transaction_rule,
      condition_type: "compound",
      operator: "and",
      sub_conditions: [
        Rule::Condition.new(
          condition_type: "transaction_merchant",
          operator: "=",
          value: "Whole Foods"
        ),
        Rule::Condition.new(
          condition_type: "transaction_amount",
          operator: "<",
          value: "50"
        )
      ]
    )

    filtered = parent_condition.apply(@rule_scope)
    assert_equal 1, filtered.count
  end

  test "applies compound or condition" do
    parent_condition = Rule::Condition.new(
      rule: @transaction_rule,
      condition_type: "compound",
      operator: "or",
      sub_conditions: [
        Rule::Condition.new(
          condition_type: "transaction_merchant",
          operator: "=",
          value: "Whole Foods"
        ),
        Rule::Condition.new(
          condition_type: "transaction_amount",
          operator: "<",
          value: "50"
        )
      ]
    )

    filtered = parent_condition.apply(@rule_scope)
    assert_equal 3, filtered.count
  end
end
