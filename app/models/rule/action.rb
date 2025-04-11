class Rule::Action < ApplicationRecord
  belongs_to :rule

  validates :action_type, presence: true

  def apply(resource_scope)
    executor.execute(resource_scope, value)
  end

  def options
    executor.options
  end

  def executor
    rule.registry.get_executor!(action_type)
  end
end
