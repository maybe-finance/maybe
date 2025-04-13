class Rule::Action < ApplicationRecord
  belongs_to :rule

  validates :action_type, presence: true

  def apply(resource_scope, ignore_attribute_locks: false)
    executor.execute(resource_scope, value: value, ignore_attribute_locks: ignore_attribute_locks)
  end

  def options
    executor.options
  end

  def executor
    rule.registry.get_executor!(action_type)
  end
end
