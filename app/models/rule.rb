class Rule < ApplicationRecord
  UnsupportedResourceTypeError = Class.new(StandardError)

  belongs_to :family
  has_many :conditions, dependent: :destroy
  has_many :actions, dependent: :destroy

  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :actions, allow_destroy: true

  validates :resource_type, presence: true
  validate :no_nested_compound_conditions

  class << self
    # def transaction_template
    #   new(
    #     resource_type: "transaction",
    #     conditions: [
    #       Condition.new(
    #         condition_type: "transaction_name",
    #         operator: "=",
    #         value: nil
    #       )
    #     ]
    #   )
    # end

    def transaction_template
      new(
        resource_type: "transaction",
        conditions: [
          Condition.new(
            condition_type: "transaction_name",
            operator: "=",
            value: nil
          ),
          Condition.new(
            condition_type: "compound",
            operator: "or",
            value: nil,
            sub_conditions: [
              Condition.new(
                condition_type: "transaction_name",
                operator: "like",
                value: nil
              ),
              Condition.new(
                condition_type: "transaction_name",
                operator: "like",
                value: nil
              ),
              Condition.new(
                condition_type: "compound",
                operator: "and",
                value: nil,
                sub_conditions: [
                  Condition.new(
                    condition_type: "transaction_amount",
                    operator: ">",
                    value: nil
                  ),
                  Condition.new(
                    condition_type: "transaction_amount",
                    operator: "<",
                    value: nil
                  )
                ]
              )
            ]
          ),
          Condition.new(
            condition_type: "transaction_name",
            operator: "=",
            value: nil
          )
        ],
        actions: [
          Action.new(
            action_type: "set_category",
            value: nil
          )
        ]
      )
    end
  end

  def action_types
    registry.action_executors.map { |option| [ option.label, option.key ] }
  end

  def condition_types
    registry.condition_filters.map { |option| [ option.label, option.key ] }
  end

  def registry
    @registry ||= case resource_type
    when "transaction"
      Rule::Registry::TransactionResource.new(self)
    else
      raise UnsupportedResourceTypeError, "Unsupported resource type: #{resource_type}"
    end
  end

  def apply
    scope = registry.resource_scope

    # 1. Prepare the query with joins required by conditions
    conditions.each do |condition|
      if condition.compound?
        condition.sub_conditions.each do |sub_condition|
          scope = sub_condition.prepare(scope)
        end
      else
        scope = condition.prepare(scope)
      end
    end

    # 2. Apply the conditions to the query
    conditions.each do |condition|
      scope = condition.apply(scope)
    end

    # 3. Apply the actions to the resources resulting from the query
    actions.each do |action|
      action.apply(scope)
    end
  end

  private
    # Validation: To keep rules simple and easy to understand, we don't allow nested compound conditions.
    def no_nested_compound_conditions
      return true if conditions.none? { |condition| condition.compound? }

      conditions.each do |condition|
        if condition.compound?
          if condition.sub_conditions.any? { |sub_condition| sub_condition.compound? }
            errors.add(:base, "Compound conditions cannot be nested")
          end
        end
      end
    end
end
