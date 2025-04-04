class Rule::Action < ApplicationRecord
  UnsupportedActionError = Class.new(StandardError)

  belongs_to :rule

  validates :action_type, presence: true

  def apply(resource_scope)
    config = registry.get_config(action_type)
    raise UnsupportedActionError, "Unsupported action type: #{action_type}" unless config
    config.builder.call(resource_scope, value)
  end

  def registry
    @registry ||= rule.actions_registry
  end
end
