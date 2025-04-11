class RuleJob < ApplicationJob
  queue_as :default

  def perform(rule)
    rule.apply
  end
end
