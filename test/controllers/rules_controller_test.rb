require "test_helper"

class RulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "should get new" do
    get new_rule_url(resource_type: "transaction")
    assert_response :success
  end

  test "should get edit" do
    get edit_rule_url(rules(:one))
    assert_response :success
  end

  # "Set all transactions with a name like 'starbucks' and an amount between 20 and 40 to the 'food and drink' category"
  test "creates rule with nested conditions" do
    post rules_url, params: {
      rule: {
        effective_date: 30.days.ago.to_date,
        resource_type: "transaction",
        conditions_attributes: {
          "0" => {
            condition_type: "transaction_name",
            operator: "like",
            value: "starbucks"
          },
          "1" => {
            condition_type: "compound",
            operator: "and",
            sub_conditions_attributes: {
              "0" => {
                condition_type: "transaction_amount",
                operator: ">",
                value: 20
              },
              "1" => {
                condition_type: "transaction_amount",
                operator: "<",
                value: 40
              }
            }
          }
        },
        actions_attributes: {
          "0" => {
            action_type: "set_transaction_category",
            value: categories(:food_and_drink).id
          }
        }
      }
    }

    rule = @user.family.rules.order("created_at DESC").first

    # Rule
    assert_equal "transaction", rule.resource_type
    assert_not rule.active # Not active by default
    assert_equal 30.days.ago.to_date, rule.effective_date

    # Conditions assertions
    assert_equal 2, rule.conditions.count
    compound_condition = rule.conditions.find { |condition| condition.condition_type == "compound" }
    assert_equal "compound", compound_condition.condition_type
    assert_equal 2, compound_condition.sub_conditions.count

    # Actions assertions
    assert_equal 1, rule.actions.count
    assert_equal "set_transaction_category", rule.actions.first.action_type
    assert_equal categories(:food_and_drink).id, rule.actions.first.value

    assert_redirected_to confirm_rule_url(rule)
  end

  test "can update rule" do
    rule = rules(:one)

    assert_difference -> { Rule.count } => 0,
      -> { Rule::Condition.count } => 1,
      -> { Rule::Action.count } => 1 do
      patch rule_url(rule), params: {
        rule: {
          active: false,
          conditions_attributes: {
            "0" => {
              id: rule.conditions.first.id,
              value: "new_value"
            },
            "1" => {
              condition_type: "transaction_amount",
              operator: ">",
              value: 100
            }
          },
          actions_attributes: {
            "0" => {
              id: rule.actions.first.id,
              value: "new_value"
            },
            "1" => {
              action_type: "set_transaction_tags",
              value: tags(:one).id
            }
          }
        }
      }
    end

    rule.reload

    assert_not rule.active
    assert_equal "new_value", rule.conditions.order("created_at ASC").first.value
    assert_equal "new_value", rule.actions.order("created_at ASC").first.value
    assert_equal tags(:one).id, rule.actions.order("created_at ASC").last.value
    assert_equal "100", rule.conditions.order("created_at ASC").last.value

    assert_redirected_to rules_url
  end

  test "can destroy conditions and actions while editing" do
    rule = rules(:one)

    assert_equal 1, rule.conditions.count
    assert_equal 1, rule.actions.count

    patch rule_url(rule), params: {
      rule: {
        conditions_attributes: {
          "0" => { id: rule.conditions.first.id, _destroy: true },
          "1" => {
            condition_type: "transaction_name",
            operator: "like",
            value: "new_condition"
          }
        },
        actions_attributes: {
          "0" => { id: rule.actions.first.id, _destroy: true },
          "1" => {
            action_type: "set_transaction_tags",
            value: tags(:one).id
          }
        }
      }
    }

    assert_redirected_to rules_url

    rule.reload

    assert_equal 1, rule.conditions.count
    assert_equal 1, rule.actions.count
  end

  test "can destroy rule" do
    rule = rules(:one)

    assert_difference [ "Rule.count", "Rule::Condition.count", "Rule::Action.count" ], -1 do
      delete rule_url(rule)
    end

    assert_redirected_to rules_url
  end
end
