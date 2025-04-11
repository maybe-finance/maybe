class Rule < ApplicationRecord
  UnsupportedResourceTypeError = Class.new(StandardError)

  belongs_to :family
  has_many :conditions, dependent: :destroy
  has_many :actions, dependent: :destroy

  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :actions, allow_destroy: true

  validates :resource_type, presence: true
  validate :no_nested_compound_conditions

  # Every rule must have at least 1 condition + action
  validate :min_conditions_and_actions
  validate :no_duplicate_actions

  def action_executors
    registry.action_executors
  end

  def condition_filters
    registry.condition_filters
  end

  def title
    "Test title"
  end

  def registry
    @registry ||= case resource_type
    when "transaction"
      Rule::Registry::TransactionResource.new(self)
    else
      raise UnsupportedResourceTypeError, "Unsupported resource type: #{resource_type}"
    end
  end

  def affected_resource_count
    matching_resources_scope.count
  end

  def matching_resources_scope
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

    scope
  end

  def apply
    actions.each do |action|
      action.apply(matching_resources_scope)
    end
  end

  def apply_later
    RuleJob.perform_later(self)
  end

  private
    def min_conditions_and_actions
      if conditions.reject(&:marked_for_destruction?).empty?
        errors.add(:base, "must have at least one condition")
      end

      if actions.reject(&:marked_for_destruction?).empty?
        errors.add(:base, "must have at least one action")
      end
    end

    def no_duplicate_actions
      action_types = actions.reject(&:marked_for_destruction?).map(&:action_type)

      errors.add(:base, "Rule cannot have duplicate actions #{action_types.inspect}") if action_types.uniq.count != action_types.count
    end

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
