class Rule < ApplicationRecord
  UnsupportedResourceTypeError = Class.new(StandardError)

  belongs_to :family
  has_many :conditions, dependent: :destroy
  has_many :actions, dependent: :destroy

  validates :resource_type, presence: true

  def conditions_registry
    case resource_type
    when "transaction"
      Rule::Condition::TransactionRegistry.new(family)
    else
      raise UnsupportedResourceTypeError, "Unsupported resource type: #{resource_type}"
    end
  end

  def actions_registry
    case resource_type
    when "transaction"
      Rule::Action::TransactionRegistry.new(family)
    else
      raise UnsupportedResourceTypeError, "Unsupported resource type: #{resource_type}"
    end
  end

  def apply
    scope = resource_scope

    conditions.each do |condition|
      scope = condition.apply(scope)
    end

    actions.each do |action|
      action.apply(scope)
    end
  end

  private
    def resource_scope
      scope = base_resource_scope

      conditions.each do |condition|
        if condition.compound?
          condition.sub_conditions.each do |sub_condition|
            scope = sub_condition.prepare(scope)
          end
        else
          scope = condition.prepare(scope)
        end
      end

      scope
    end

    def base_resource_scope
      case resource_type
      when "transaction"
        family.transactions.active
      else
        raise UnsupportedResourceTypeError, "Unsupported resource type: #{resource_type}"
      end
    end
end
