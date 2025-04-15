class RuleJob < ApplicationJob
  queue_as :default

  def perform(rule, ignore_attribute_locks: false)
    rule.apply(ignore_attribute_locks: ignore_attribute_locks)
  end
end
