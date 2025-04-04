class Rule::Condition < ApplicationRecord
  include Compoundable

  UnsupportedConditionTypeError = Class.new(StandardError)

  OPERATORS = [ "and", "or", "like", ">", ">=", "<", "<=", "=" ]

  belongs_to :rule, optional: -> { where.not(parent_id: nil) }

  validates :operator, inclusion: { in: OPERATORS }, allow_nil: true
  validates :condition_type, presence: true

  def apply(scope)
    if compound?
      build_compound_scope(scope)
    else
      config.builder.call(scope, operator, value)
    end
  end

  def prepare(scope)
    config.preparer.call(scope)
  end

  private
    def config
      config ||= rule.conditions_registry.get_config(condition_type)
      raise UnsupportedConditionTypeError, "Unsupported condition type: #{condition_type}" unless config
      config
    end
end
