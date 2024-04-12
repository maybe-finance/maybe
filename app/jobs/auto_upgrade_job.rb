class AutoUpgradeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "Placeholder: AutoUpgradeJob.perform"
  end
end
