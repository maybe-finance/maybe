class Rule::Action < ApplicationRecord
  belongs_to :rule

  validates :action_type, presence: true

  def apply(resource_scope, ignore_attribute_locks: false)
    executor.execute(resource_scope, value: value, ignore_attribute_locks: ignore_attribute_locks)
  end

  def options
    executor.options
  end

  def value_display
    if value.present?
      if options
        options.find { |option| option.last == value }&.first
      else
        ""
      end
    else
      ""
    end
  end

  def executor
    rule.registry.get_executor!(action_type)
  end
end
