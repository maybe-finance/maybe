class Rule < ApplicationRecord
  belongs_to :family
  has_many :conditions, dependent: :destroy
  has_many :actions, dependent: :destroy

  validates :effective_date, presence: true

  def get_operator_symbol(operator)
    case operator
    when "gt"
      ">"
    when "lt"
      "<"
    when "eq"
      "="
    end
  end

  def apply
    case resource_type
    when "transaction"
      scope = family.transactions

      conditions.each do |condition|
        case condition.condition_type
        when "match_merchant"
          scope = scope.left_joins(:merchant).where(merchant: { name: condition.value })
        when "compare_amount"
          operator_symbol = get_operator_symbol(condition.operator)
          scope = scope.joins(:entry)
                       .where("account_entries.amount #{Arel.sql(operator_symbol)} ?", condition.value)
        when "compound"
          subconditions = condition.conditions

          subconditions.each do |subcondition|
            case condition.operator
            when "and"
              case subcondition.condition_type
              when "match_merchant"
                scope = scope.left_joins(:merchant).where(merchant: { name: subcondition.value })
              when "compare_amount"
                operator_symbol = get_operator_symbol(subcondition.operator)
                scope = scope.joins(:entry)
                             .where("account_entries.amount #{Arel.sql(operator_symbol)} ?", subcondition.value.to_f)
              end
            when "or"
              raise "not implemented yet"
            else
              raise "Invalid compound operator"
            end
          end
        else
          raise "Unsupported condition type: #{condition.condition_type}"
        end
      end

      scope.each do |transaction|
        actions.each do |action|
          case action.action_type
          when "set_category"
            category = family.categories.find_by(name: action.value)
            transaction.update!(category: category)
          else
            raise "Unsupported action type: #{action.action_type}"
          end
        end
      end
    else
      raise "Unsupported resource type: #{resource_type}"
    end
  end
end
