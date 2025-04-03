class Rule::Condition < ApplicationRecord
  UnsupportedOperatorError = Class.new(StandardError)
  UnsupportedConditionTypeError = Class.new(StandardError)

  OPERATORS = [ "and", "or", "like", ">", ">=", "<", "<=", "=" ]

  belongs_to :rule, optional: -> { where.not(parent_id: nil) }
  belongs_to :parent, class_name: "Rule::Condition", optional: true
  has_many :sub_conditions, class_name: "Rule::Condition", foreign_key: :parent_id, dependent: :destroy

  validates :operator, inclusion: { in: OPERATORS }, allow_nil: true
  validates :condition_type, presence: true

  def apply(resource_scope)
    filtered_scope = resource_scope

    case condition_type
    when "compound"
      filtered_scope = build_compound_scope(filtered_scope)
    when "transaction_name"
      filtered_scope = filtered_scope.where(build_sanitized_comparison_sql("account_entries.name", operator), value)
    when "transaction_amount"
      filtered_scope = filtered_scope.where(build_sanitized_comparison_sql("account_entries.amount", operator), value.to_d)
    when "transaction_merchant"
      filtered_scope = filtered_scope.left_joins(:merchant).where(merchant: { name: value })
    else
      raise UnsupportedConditionTypeError, "Unsupported condition type: #{condition_type}"
    end

    filtered_scope
  end

  private
    def build_sanitized_comparison_sql(field, operator)
      "#{field} #{sanitize_operator(operator)} ?"
    end

    def sanitize_operator(operator)
      raise UnsupportedOperatorError, "Unsupported operator: #{operator}" unless OPERATORS.include?(operator)
      operator
    end

    def build_compound_scope(filtered_scope)
      if operator == "or"
        combined_scope = nil

        sub_conditions.each do |sub_condition|
          sub_scope = sub_condition.apply(filtered_scope)

          if combined_scope.nil?
            combined_scope = sub_scope
          else
            combined_scope = combined_scope.or(sub_scope)
          end
        end

        filtered_scope = combined_scope || filtered_scope
      else
        sub_conditions.each do |sub_condition|
          filtered_scope = sub_condition.apply(filtered_scope)
        end
      end

      filtered_scope
    end
end
