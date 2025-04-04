class RuleProcessorJob < ApplicationJob
  queue_as :default

  def perform(family)
    family.rules.each do |rule|
      rule.apply
    end
  end
end
